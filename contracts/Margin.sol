//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IMargin.sol";
import "./IOracle.sol";
import "./IVPool.sol";
import "./lib/UniswapV2Router02.sol";

contract Margin is IMargin, Context {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IOracle private oracle;
    IVPool private pool;

    struct BorrowAccount {
        uint256 collateral;
        uint256 borrowed;
        uint256 initialPrice;
        uint256 borrowTime;
        uint256 initialBorrowTime;
    }
    struct BorrowPeriod {
        uint256 totalBorrowed;
        mapping(address => mapping(IERC20 => BorrowAccount)) collateral; // account => token => borrow - this way the same account can have different borrows with different collaterals independently
    }
    mapping(uint256 => mapping(IERC20 => BorrowPeriod)) private borrowPeriods;
    uint256 private minBorrowLength;

    uint256 private minMarginLevel; // Stored as the percentage above equilibrium threshold

    uint256 private maxInterestPercent;

    constructor(IOracle oracle_, IVPool pool_, uint256 minBorrowLength_, uint256 maxInterestPercent_, uint256 minMarginLevel_) {
        oracle = oracle_;
        pool = pool_;
        minBorrowLength = minBorrowLength_;
        maxInterestPercent = maxInterestPercent_;
        minMarginLevel = minMarginLevel_;
    }

    // ======== Modifiers ========

    modifier approvedOnly(IERC20 _token) {
        require(pool.isApproved(_token), "This token has not been approved");
        _;
    }

    // ======== Calculations ========

    function getMinBorrowLength() public view override returns (uint256) {
        return minBorrowLength;
    }

    function compensationPercentage() public view override returns (uint256) {
        return minMarginLevel.mul(100).div(minMarginLevel.add(100)).div(10);
    }

    function totalBorrowed(IERC20 _token) public view override returns (uint256) {
        // Calculate the amount borrowed for the current token for the given pool for the given period
        uint256 periodId = pool.currentPeriodId();
        return borrowPeriods[periodId][_token].totalBorrowed;
    }

    function liquidityAvailable(IERC20 _token) public view override returns (uint256) {
        // Calculate the liquidity available for the current token for the current period
        uint256 liquidity = pool.getLiquidity(_token, pool.currentPeriodId());
        uint256 borrowed = totalBorrowed(_token);

        return liquidity - borrowed;
    }

    function _calculateMarginLevelHelper(uint256 _deposited, uint256 _currentBorrowPrice, uint256 _initialBorrowPrice, uint256 _interest) private view returns (uint256) {
        uint256 retValue;
        { retValue = oracle.getDecimals(); }
        { retValue = retValue.mul(_deposited.add(_currentBorrowPrice)); }
        { retValue = retValue.div(_initialBorrowPrice.add(_interest)); }
        
        return retValue;
    }

    function calculateMarginLevel(uint256 _deposited, uint256 _initialBorrowPrice, uint256 _borrowTime, uint256 _amountBorrowed, IERC20 _collateral, IERC20 _borrowed) public view override returns (uint256) {
        if (_amountBorrowed == 0) return oracle.getDecimals().mul(999);

        uint256 currentBorrowPrice;
        { currentBorrowPrice = oracle.pairPrice(_borrowed, _collateral).mul(_amountBorrowed).div(oracle.getDecimals()); }

        uint256 interest;
        { interest = calculateInterest(_borrowed, _initialBorrowPrice, _borrowTime); }
        
        return _calculateMarginLevelHelper(_deposited, currentBorrowPrice, _initialBorrowPrice, interest);
    }

    function getMinMarginLevel() public view override returns (uint256) {
        // Return the minimum margin level before liquidation
        return minMarginLevel.add(100).mul(oracle.getDecimals()).div(100);
    }

    function getMarginLevel(address _account, IERC20 _collateral, IERC20 _borrowed) public view override returns (uint256) {
        // Get the borrowed period and and borrowed asset data and calculate and return accounts margin level
        BorrowAccount storage borrowAccount = borrowPeriods[pool.currentPeriodId()][_borrowed].collateral[_account][_collateral];
        return calculateMarginLevel(borrowAccount.collateral, borrowAccount.initialPrice, borrowAccount.initialBorrowTime, borrowAccount.borrowed, _collateral, _borrowed);
    }

    function calculateInterestRate(IERC20 _borrowed) public view override returns (uint256) {
        // Calculate the interest rate for a given asset
        // interest = totalBorrowed / (totalBorrowed + liquidity)
        uint256 _totalBorrowed = totalBorrowed(_borrowed);
        uint256 liquidity = liquidityAvailable(_borrowed);

        return _totalBorrowed.mul(maxInterestPercent).mul(oracle.getDecimals()).div(liquidity.add(_totalBorrowed)).div(100).div(pool.getPeriodLength());
    }

    function calculateInterest(IERC20 _borrowed, uint256 _initialBorrow, uint256 _borrowTime) public view override returns (uint256) {
        // interest = maxInterestPercent * priceBorrowedInitially * interestRate * (timeBorrowed / interestPeriod)
        uint256 retValue;
        { retValue = _initialBorrow.mul(calculateInterestRate(_borrowed)); }
        { retValue = retValue.mul(block.timestamp.sub(_borrowTime)).div(oracle.getDecimals()); }

        return retValue;
    }

    // ======== Deposit ========

    function deposit(IERC20 _collateral, IERC20 _borrowed, uint256 _amount) external override approvedOnly(_collateral) approvedOnly(_borrowed) {
        // Make sure the amount is greater than 0
        require(_amount > 0, "Amount must be greater than 0");
        uint256 periodId = pool.currentPeriodId();

        // Store funds in the account for the given asset they wish to borrow
        _collateral.safeTransferFrom(_msgSender(), address(this), _amount);

        BorrowPeriod storage borrowPeriod = borrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        borrowAccount.collateral = borrowAccount.collateral.add(_amount);
        emit Deposit(_msgSender(), periodId, _collateral, _borrowed, _amount);
    }

    function collateralOf(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _periodId) external view override returns (uint256) {
        // Return the collateral of the account
        BorrowPeriod storage borrowPeriod = borrowPeriods[_periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        return borrowAccount.collateral;
    }

    // ======== Borrow ========

    function _borrowHelper(BorrowAccount storage _borrowAccount, BorrowPeriod storage _borrowPeriod, IERC20 _collateral, IERC20 _borrowed, uint256 _amount) private {
        // Require that the borrowed amount will be above the required margin level
        uint256 borrowInitialPrice = oracle.pairPrice(_borrowed, _collateral).mul(_amount).div(oracle.getDecimals());
        require(calculateMarginLevel(_borrowAccount.collateral, _borrowAccount.initialPrice.add(borrowInitialPrice), _borrowAccount.initialBorrowTime, _borrowAccount.borrowed.add(_amount), _collateral, _borrowed) > getMinMarginLevel(), "This deposited amount is not enough to exceed minimum margin level");

        // Update the balances of the borrowed value
        _borrowPeriod.totalBorrowed = _borrowPeriod.totalBorrowed.add(_amount);

        _borrowAccount.initialPrice = _borrowAccount.initialPrice.add(borrowInitialPrice);
        _borrowAccount.borrowed = _borrowAccount.borrowed.add(_amount);
        _borrowAccount.borrowTime = block.timestamp;
    }

    function borrow(IERC20 _collateral, IERC20 _borrowed, uint256 _amount) external override approvedOnly(_collateral) approvedOnly(_borrowed) {
        // Requirements for borrowing
        require(_amount > 0, "Amount must be greater than 0");
        uint256 periodId = pool.currentPeriodId();
        require(!pool.isPrologue(periodId), "Cannot borrow during prologue");
        require(liquidityAvailable(_borrowed) >= _amount, "Amount to borrow exceeds available liquidity");

        BorrowPeriod storage borrowPeriod = borrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        if (borrowAccount.borrowed == 0) borrowAccount.initialBorrowTime = block.timestamp;

        _borrowHelper(borrowAccount, borrowPeriod, _collateral, _borrowed, _amount);

        emit Borrow(_msgSender(), periodId, _collateral, _borrowed, _amount);
    }

    function debtOf(address _account, IERC20 _collateral, IERC20 _borrowed) external view override returns (uint256) {
        // Return the collateral of the account
        uint256 periodId = pool.currentPeriodId();
        BorrowPeriod storage borrowPeriod = borrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        return borrowAccount.borrowed;
    }

    function borrowTime(address _account, IERC20 _collateral, IERC20 _borrowed) external view override returns (uint256) {
        // Return the collateral of the account
        uint256 periodId = pool.currentPeriodId();
        BorrowPeriod storage borrowPeriod = borrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        return borrowAccount.borrowTime;
    }

    // ======== Repay and withdraw ========

    function _balanceHelper(IERC20 _collateral, IERC20 _borrowed, BorrowAccount memory _borrowAccount) private view returns (uint256, uint256) {
        uint256 interest = calculateInterest(_borrowed, _borrowAccount.initialPrice, _borrowAccount.initialBorrowTime);
        uint256 borrowedCurrentPrice = oracle.pairPrice(_borrowed, _collateral).mul(_borrowAccount.borrowed).div(oracle.getDecimals());
        return (interest, borrowedCurrentPrice);
    }

    function balanceOf(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _periodId) public view override returns (uint256) {
        // The value returned from repaying a margin in terms of the deposited asset
        BorrowAccount storage borrowAccount = borrowPeriods[_periodId][_borrowed].collateral[_account][_collateral];

        (uint256 interest, uint256 borrowedCurrentPrice) = _balanceHelper(_collateral, _borrowed, borrowAccount);
        if (!pool.isCurrentPeriod(_periodId)) return borrowAccount.collateral.sub(interest);

        return borrowAccount.collateral.add(borrowedCurrentPrice).sub(borrowAccount.initialPrice).sub(interest);
    }

    function _repayGreaterHelper(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _balAfterRepay, BorrowAccount storage _borrowAccount) private {
        // Convert the accounts tokens back to the deposited asset
        uint256 payout = oracle.pairPrice(_collateral, _borrowed).mul(_balAfterRepay.sub(_borrowAccount.collateral)).div(oracle.getDecimals());

        // Get the amount in borrowed assets that the earned balance is worth and swap them for the given asset
        pool.withdraw(_borrowed, payout);
        address[] memory path = new address[](2);
        path[0] = address(_borrowed);
        path[1] = address(_collateral);

        address router = address(oracle.getRouter());
        _collateral.safeApprove(address(router), payout);
        uint256 amountOut = UniswapV2Router02(router).swapExactTokensForTokens(payout, 0, path, address(this), block.timestamp + 1 hours)[1];

        // Provide a reward to the user who repayed the account if they are not the account owner
        _borrowAccount.collateral = _borrowAccount.collateral.add(amountOut);
        if (_account != _msgSender()) {
            uint256 reward = amountOut.mul(compensationPercentage()).div(100);
            _collateral.safeTransfer(_msgSender(), reward);

            _borrowAccount.collateral = _borrowAccount.collateral.sub(reward);
        }
    }

    function _repayLessEqualHelper(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _balAfterRepay, BorrowAccount storage _borrowAccount) private {
        // Amount the user has to repay the protocol
        uint256 repayAmount = _borrowAccount.collateral.sub(_balAfterRepay);
        _borrowAccount.collateral = _balAfterRepay;

        // Swap the repay value back for the borrowed asset
        address[] memory path = new address[](2);
        path[0] = address(_collateral);
        path[1] = address(_borrowed);

        address router = address(oracle.getRouter());
        _collateral.safeApprove(address(router), repayAmount);
        uint256 amountOut = UniswapV2Router02(router).swapExactTokensForTokens(repayAmount, 0, path, address(this), block.timestamp + 1 hours)[1];

        // Provide a reward to the user who repayed the account if they are not the account owner
        uint256 reward = 0;
        if (_account != _msgSender()) {
            reward = amountOut.mul(compensationPercentage()).div(100);
            _borrowed.safeTransfer(_msgSender(), reward);
        }

        // Return the assets back to the pool
        uint256 depositValue = amountOut.sub(reward);
        _borrowed.safeApprove(address(pool), depositValue);
        pool.deposit(_borrowed, depositValue);
    }

    function repay(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _periodId) external override approvedOnly(_collateral) approvedOnly(_borrowed) {
        // If the period has entered the epilogue phase, then anyone may repay the account
        require(_account == _msgSender() || pool.isEpilogue(_periodId) || !pool.isCurrentPeriod(_periodId), "Only the owner may repay before the epilogue period has started");

        // Repay off the margin and update the users collateral to reflect it
        BorrowPeriod storage borrowPeriod = borrowPeriods[_periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        require(borrowAccount.borrowed > 0, "No debt to repay");
        require(block.timestamp > borrowAccount.borrowTime + minBorrowLength || pool.isEpilogue(_periodId), "Cannot repay until minimum borrow period is over");

        uint256 balAfterRepay = balanceOf(_account, _collateral, _borrowed, _periodId);
        if (balAfterRepay > borrowAccount.collateral) {
            _repayGreaterHelper(_account, _collateral, _borrowed, balAfterRepay, borrowAccount);
        } else {
            _repayLessEqualHelper(_account, _collateral, _borrowed, balAfterRepay, borrowAccount);
        }

        // Update the borrowed
        borrowAccount.initialPrice = 0;
        borrowPeriod.totalBorrowed = borrowPeriod.totalBorrowed.sub(borrowAccount.borrowed);
        borrowAccount.borrowed = 0;
        emit Repay(_msgSender(), _periodId, _collateral, _borrowed, balAfterRepay);
    }

    function withdraw(IERC20 _collateral, IERC20 _borrowed, uint256 _amount, uint256 _periodId) external override approvedOnly(_collateral) approvedOnly(_borrowed) {
        // Check that the user does not have any debt
        BorrowPeriod storage borrowPeriod = borrowPeriods[_periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        // Require the amount in the balance and the user not to be borrowing
        require(borrowAccount.borrowed == 0, "Cannot withdraw with outstanding debt, repay first");
        require(borrowAccount.collateral >= _amount, "Insufficient balance to withdraw");

        // Update the balance and transfer
        borrowAccount.collateral = borrowAccount.collateral.sub(_amount);
        _collateral.safeTransfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _periodId, _collateral, _borrowed, _amount);
    }

    // ======== Liquidate ========

    function isLiquidatable(address _account, IERC20 _collateral, IERC20 _borrowed) public view override returns (bool) {
        // Return if a given account is liquidatable
        return getMarginLevel(_account, _collateral, _borrowed) <= getMinMarginLevel(); 
    }

    function flashLiquidate(address _account, IERC20 _collateral, IERC20 _borrowed) external override approvedOnly(_collateral) approvedOnly(_borrowed) {
        // Liquidate an at risk account
        uint256 periodId = pool.currentPeriodId();
        require(isLiquidatable(_account, _borrowed, _collateral), "This account is not liquidatable");

        BorrowPeriod storage borrowPeriod = borrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        // Swap the users collateral for assets
        address[] memory path = new address[](2);
        path[0] = address(_collateral);
        path[1] = address(_borrowed);

        address router = address(oracle.getRouter());
        _collateral.safeApprove(address(router), borrowAccount.collateral);
        uint256 amountOut = UniswapV2Router02(router).swapExactTokensForTokens(borrowAccount.collateral, 0, path, address(this), block.timestamp + 1 hours)[1];

        // Compensate the liquidator
        uint256 reward = amountOut.mul(compensationPercentage()).div(100);
        _borrowed.safeTransfer(_msgSender(), reward);
        uint256 depositValue = amountOut.sub(reward);
        _borrowed.safeApprove(address(pool), depositValue);
        pool.deposit(_borrowed, depositValue);

        emit FlashLiquidation(_account, periodId, _msgSender(), _collateral, _borrowed, borrowAccount.collateral);

        // Update the users account
        borrowAccount.collateral = 0;
        borrowPeriod.totalBorrowed = borrowPeriod.totalBorrowed.sub(borrowAccount.borrowed);
        borrowAccount.borrowed = 0;
        borrowAccount.initialPrice = 0;
    }
}