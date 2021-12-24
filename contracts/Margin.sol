//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Oracle.sol";
import "./LPool.sol";
import "./lib/UniswapV2Router02.sol";
import "./lib/MarginCore.sol";

contract Margin is Ownable, MarginCore {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(uint256 => mapping(IERC20 => BorrowPeriod)) private BorrowPeriods;

    constructor(Oracle oracle_, LPool pool_, uint256 minBorrowLength_, uint256 maxInterestPercent_, uint256 minMarginThreshold_)
        MarginCore(oracle_, pool_, minBorrowLength_, maxInterestPercent_, minMarginThreshold_)
    {}

    // ======== Getters ========

    /** @dev Get the percentage rewarded to a user who performed an autonomous operation */
    function compensationPercentage() public view override returns (uint256) {
        return minMarginThreshold.mul(100).div(minMarginThreshold.add(100)).div(10);
    }

    /** @dev Return the total amount of a given asset borrowed */
    function borrowed(IERC20 _token) public view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        return BorrowPeriods[periodId][_token].totalBorrowed;
    }

    /** @dev Get the margin level of the given account */
    function marginLevel(address _account, IERC20 _collateral, IERC20 _borrowed) public view returns (uint256) {
        BorrowAccount storage borrowAccount = BorrowPeriods[pool.currentPeriodId()][_borrowed].collateral[_account][_collateral];
        uint256 interest = calculateInterest(_borrowed, borrowAccount.initialPrice, borrowAccount.initialBorrowTime);
        return _marginLevel(borrowAccount.collateral, borrowAccount.initialPrice, borrowAccount.borrowed, _collateral, _borrowed, interest);
    }

    /** @dev Get the percentage of the pool of a given token being utilized by borrowers */
    function utilizationRate(IERC20 _token) public view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        uint256 _borrowed = borrowed(_token);
        uint256 _tvl = pool.tvl(_token, periodId);
        return _borrowed.mul(oracle.decimals()).div(_tvl);
    }

    /** @dev Get the interest rate for a given asset per second
        interest = maxInterestRate * totalBorrowed / (totalBorrowed + liquidity) */
    function interestRate(IERC20 _token) public view returns (uint256) {
        uint256 utilization = utilizationRate(_token);
        return utilization.mul(maxInterestPercent).div(100).div(pool.periodLength());
    }

    /** @dev Calculate the interest at the current time for a given asset from the amount initially borrowed
        interest = maxInterestPercent * priceBorrowedInitially * interestRate * (timeBorrowed / interestPeriod) */
    function calculateInterest(IERC20 _borrowed, uint256 _initialBorrow, uint256 _borrowTime) public view override returns (uint256) {
        uint256 retValue;
        { retValue = _initialBorrow.mul(interestRate(_borrowed)); }
        { retValue = retValue.mul(block.timestamp.sub(_borrowTime)).div(oracle.decimals()); }
        return retValue;
    }

    // ======== Deposit and withdraw ========


    // ======== Borrow ========

    /** @dev Borrow a specified number of the given asset against the collateral */
    function borrow(IERC20 _collateral, IERC20 _borrowed, uint256 _amount) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        uint256 periodId = pool.currentPeriodId();
        require(_amount > 0, "Amount must be greater than 0");
        require(!pool.isPrologue(periodId) && !pool.isEpilogue(periodId), "Cannot borrow during the prologue or epilogue");
        require(pool.liquidity(_borrowed, periodId) >= _amount, "Amount to borrow exceeds available liquidity");
        require(_collateral != _borrowed, "Cannot borrow against the same asset");

        BorrowPeriod storage borrowPeriod = BorrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        require(borrowAccount.collateral > 0 && borrowAccount.collateral >= minCollateral(_collateral), "Not enough collateral to borrow against");

        _borrow(borrowAccount, borrowPeriod, _collateral, _borrowed, _amount);

        emit Borrow(_msgSender(), periodId, _collateral, _borrowed, _amount);
    }

    /** @dev Get the most recent borrow time for a given account */
    function borrowTime(address _account, IERC20 _collateral, IERC20 _borrowed) external view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        BorrowAccount storage borrowAccount = BorrowPeriods[periodId][_borrowed].collateral[_account][_collateral];
        return borrowAccount.borrowTime;
    }

    /** @dev Get the initial borrow time of the account */
    function initialBorrowTime(address _account, IERC20 _collateral, IERC20 _borrowed) external view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        BorrowAccount storage borrowAccount = BorrowPeriods[periodId][_borrowed].collateral[_account][_collateral];
        return borrowAccount.initialBorrowTime;
    }

    // ======== Repay and withdraw ========

    /** @dev Repay the borrowed amount for the given asset and collateral */
    function repay(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _periodId) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        // If the period has entered the epilogue phase, then anyone may repay the account
        require(_account == _msgSender() || pool.isEpilogue(_periodId) || !pool.isCurrentPeriod(_periodId), "Only the owner may repay before the epilogue period");

        // Repay off the margin and update the users collateral to reflect it
        BorrowPeriod storage borrowPeriod = BorrowPeriods[_periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        require(borrowAccount.borrowed > 0, "No debt to repay");
        require(block.timestamp > borrowAccount.borrowTime + minBorrowLength || pool.isEpilogue(_periodId),
                "Cannot repay until minimum borrow period is over or epilogue has started");

        uint256 balAfterRepay = balanceOf(_account, _collateral, _borrowed, _periodId);
        if (balAfterRepay > borrowAccount.collateral) _repayGreater(_account, _collateral, _borrowed, balAfterRepay, borrowPeriod, borrowAccount);
        else _repayLessEqual(_account, _collateral, _borrowed, balAfterRepay, borrowPeriod, borrowAccount);

        emit Repay(_msgSender(), _periodId, _collateral, _borrowed, balAfterRepay);
    }

    // ======== Liquidate ========

    /** @dev Check if an account is liquidatable */
    function isLiquidatable(address _account, IERC20 _collateral, IERC20 _borrowed) public view returns (bool) {
        return marginLevel(_account, _collateral, _borrowed) < _minMarginLevel();
    }

    /** @dev Liquidates a users account that is liquidatable / below the minimum margin level */
    function flashLiquidate(address _account, IERC20 _collateral, IERC20 _borrowed) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        require(isLiquidatable(_account, _borrowed, _collateral), "This account is not liquidatable");

        uint256 periodId = pool.currentPeriodId();
        BorrowPeriod storage borrowPeriod = BorrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        // Swap the users collateral for assets
        uint256 amountOut = _swap(_collateral, _borrowed, borrowAccount.collateral);

        // Compensate the liquidator
        uint256 reward = amountOut.mul(compensationPercentage()).div(100);
        _borrowed.safeTransfer(_msgSender(), reward);
        uint256 depositValue = amountOut.sub(reward);
        _borrowed.safeApprove(address(pool), depositValue);
        pool.deposit(_borrowed, depositValue);

        // Update the users account
        borrowAccount.collateral = 0;
        borrowPeriod.totalBorrowed = borrowPeriod.totalBorrowed.sub(borrowAccount.borrowed);
        borrowAccount.borrowed = 0;
        borrowAccount.initialPrice = 0;

        emit FlashLiquidation(_account, periodId, _msgSender(), _collateral, _borrowed, borrowAccount.collateral);
    }

    // ======== Events ========

    event Deposit(address indexed account, uint256 indexed periodId, IERC20 collateral, IERC20 borrowed, uint256 amount);
    event Withdraw(address indexed account, uint256 indexed periodId, IERC20 collateral, IERC20 borrowed, uint256 amount);

    event Borrow(address indexed account, uint256 indexed periodId, IERC20 collateral, IERC20 borrowed, uint256 amount);
    event Repay(address indexed account, uint256 indexed periodId, IERC20 collateral, IERC20 borrowed, uint256 balance);

    event FlashLiquidation(address indexed account, uint256 indexed periodId, address liquidator, IERC20 collateral, IERC20 borrowed, uint256 amount);
}