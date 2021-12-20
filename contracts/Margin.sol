//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Oracle.sol";
import "./VPool.sol";
import "./lib/UniswapV2Router02.sol";

contract Margin is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    Oracle public immutable oracle;
    VPool public immutable pool;

    struct BorrowAccount {
        uint256 collateral;
        uint256 borrowed;
        uint256 initialPrice;
        uint256 borrowTime;
        uint256 initialBorrowTime;
    }
    struct BorrowPeriod {
        uint256 totalBorrowed;
        mapping(address => mapping(IERC20 => BorrowAccount)) collateral; // account => token => borrow - the same account can have different borrows with different collaterals independently
    }
    mapping(uint256 => mapping(IERC20 => BorrowPeriod)) private BorrowPeriods;
    mapping(IERC20 => uint256) private MinCollateral;
    uint256 public minBorrowLength;
    uint256 public minMarginThreshold; // Stored as the percentage above equilibrium threshold

    uint256 public maxInterestPercent;

    constructor(Oracle oracle_, VPool pool_, uint256 minBorrowLength_, uint256 maxInterestPercent_, uint256 minMarginThreshold_) {
        oracle = oracle_;
        pool = pool_;
        minBorrowLength = minBorrowLength_;
        maxInterestPercent = maxInterestPercent_;
        minMarginThreshold = minMarginThreshold_;
    }

    // ======== Modifiers ========

    modifier onlyApproved(IERC20 _token) {
        require(pool.isApproved(_token), "This token has not been approved");
        _;
    }

    /** @dev Set the minimum borrow length */
    function setMinBorrowLength(uint256 _minBorrowLength) external onlyOwner { minBorrowLength = _minBorrowLength; } 

    /** @dev Set the maximum interest percent */
    function setMaxInterestPercent(uint256 _maxInterestPercent) external onlyOwner { maxInterestPercent = _maxInterestPercent; }

    /** @dev Set the minimum margin level */
    function setMinMarginThreshold(uint256 _minMarginThreshold) external onlyOwner { minMarginThreshold = _minMarginThreshold; }

    /** @dev Set the minimum amount of collateral for a given token required to borrow against */
    function setMinCollateral(IERC20 _token, uint256 _amount) external onlyApproved(_token) onlyOwner {
        MinCollateral[_token] = _amount;
    }

    // ======== Calculations ========

    /** @dev Gets the minimum amount of collateral required to borrow a token */
    function minCollateral(IERC20 _token) public view returns (uint256) { return MinCollateral[_token]; }

    /** @dev Get the percentage rewarded to a user who performed an autonomous operation */
    function compensationPercentage() public view returns (uint256) { return minMarginThreshold.mul(100).div(minMarginThreshold.add(100)).div(10); }

    /** @dev Return the total amount of a given asset borrowed */
    function totalBorrowed(IERC20 _token) public view returns (uint256) {
        // Calculate the amount borrowed for the current token for the given pool for the given period
        uint256 periodId = pool.currentPeriodId();
        return BorrowPeriods[periodId][_token].totalBorrowed;
    }

    /** @dev Return the total amount of a given asset borrowed */
    function liquidityAvailable(IERC20 _token) public view returns (uint256) {
        // Calculate the liquidity available for the current token for the current period
        uint256 liquidity = pool.liquidity(_token, pool.currentPeriodId());
        uint256 borrowed = totalBorrowed(_token);

        return liquidity.sub(borrowed);
    }

    function _calculateMarginLevelHelper(uint256 _deposited, uint256 _currentBorrowPrice, uint256 _initialBorrowPrice, uint256 _interest) private view returns (uint256) {
        uint256 retValue;
        { retValue = oracle.decimals(); }
        { retValue = retValue.mul(_deposited.add(_currentBorrowPrice)); }
        { retValue = retValue.div(_initialBorrowPrice.add(_interest)); }
        
        return retValue;
    }

    /** @dev Calculate the margin level from the given requirements - returns the value multiplied by decimals */
    function calculateMarginLevel(uint256 _deposited, uint256 _initialBorrowPrice, uint256 _borrowTime, 
                                    uint256 _amountBorrowed, IERC20 _collateral, IERC20 _borrowed) public view returns (uint256) {
        if (_amountBorrowed == 0) return oracle.decimals().mul(999);

        uint256 currentBorrowPrice;
        { currentBorrowPrice = oracle.pairPrice(_borrowed, _collateral).mul(_amountBorrowed).div(oracle.decimals()); }

        uint256 interest;
        { interest = calculateInterest(_borrowed, _initialBorrowPrice, _borrowTime); }
        
        return _calculateMarginLevelHelper(_deposited, currentBorrowPrice, _initialBorrowPrice, interest);
    }

    /** @dev Return the minimum margin level in terms of decimals */
    function _minMarginLevel() private view returns (uint256) { return minMarginThreshold.add(100).mul(oracle.decimals()).div(100); }

    /** @dev Get the margin level of the given account */
    function marginLevel(address _account, IERC20 _collateral, IERC20 _borrowed) public view returns (uint256) {
        // Get the borrowed period and and borrowed asset data and calculate and return accounts margin level
        BorrowAccount storage borrowAccount = BorrowPeriods[pool.currentPeriodId()][_borrowed].collateral[_account][_collateral];
        return calculateMarginLevel(borrowAccount.collateral, borrowAccount.initialPrice, borrowAccount.initialBorrowTime, borrowAccount.borrowed, _collateral, _borrowed);
    }

    /** @dev Get the interest rate for a given asset */
    function calculateInterestRate(IERC20 _borrowed) public view returns (uint256) {
        // Calculate the interest rate for a given asset
        // interest = totalBorrowed / (totalBorrowed + liquidity)
        uint256 _totalBorrowed = totalBorrowed(_borrowed);
        uint256 liquidity = liquidityAvailable(_borrowed);

        return _totalBorrowed.mul(maxInterestPercent).mul(oracle.decimals()).div(liquidity.add(_totalBorrowed)).div(100).div(pool.periodLength());
    }

    /** @dev Calculate the interest at the current time for a given asset from the amount initially borrowed */
    function calculateInterest(IERC20 _borrowed, uint256 _initialBorrow, uint256 _borrowTime) public view returns (uint256) {
        // interest = maxInterestPercent * priceBorrowedInitially * interestRate * (timeBorrowed / interestPeriod)
        uint256 retValue;
        { retValue = _initialBorrow.mul(calculateInterestRate(_borrowed)); }
        { retValue = retValue.mul(block.timestamp.sub(_borrowTime)).div(oracle.decimals()); }

        return retValue;
    }

    // ======== Deposit ========

    /** @dev Deposit the given amount of collateral to borrow against a specified asset */
    function deposit(IERC20 _collateral, IERC20 _borrowed, uint256 _amount) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        // Make sure the amount is greater than 0
        require(_amount > 0, "Amount must be greater than 0");
        uint256 periodId = pool.currentPeriodId();

        // Store funds in the account for the given asset they wish to borrow
        _collateral.safeTransferFrom(_msgSender(), address(this), _amount);

        BorrowPeriod storage borrowPeriod = BorrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        borrowAccount.collateral = borrowAccount.collateral.add(_amount);
        emit Deposit(_msgSender(), periodId, _collateral, _borrowed, _amount);
    }

    /** @dev Get the collateral of an account for a given pool and period id */
    function collateralOf(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _periodId) external view returns (uint256) {
        // Return the collateral of the account
        BorrowPeriod storage borrowPeriod = BorrowPeriods[_periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        return borrowAccount.collateral;
    }

    // ======== Borrow ========

    function _borrowHelper(BorrowAccount storage _borrowAccount, BorrowPeriod storage _borrowPeriod, IERC20 _collateral, IERC20 _borrowed, uint256 _amount) private {
        // Require that the borrowed amount will be above the required margin level
        uint256 borrowInitialPrice = oracle.pairPrice(_borrowed, _collateral).mul(_amount).div(oracle.decimals());

        require(calculateMarginLevel(_borrowAccount.collateral, _borrowAccount.initialPrice.add(borrowInitialPrice),
                                    _borrowAccount.initialBorrowTime, _borrowAccount.borrowed.add(_amount), _collateral, _borrowed) > _minMarginLevel(),
                                    "This deposited collateral is not enough to exceed minimum margin level");

        // Update the balances of the borrowed value
        _borrowPeriod.totalBorrowed = _borrowPeriod.totalBorrowed.add(_amount);

        _borrowAccount.initialPrice = _borrowAccount.initialPrice.add(borrowInitialPrice);
        _borrowAccount.borrowed = _borrowAccount.borrowed.add(_amount);
        _borrowAccount.borrowTime = block.timestamp;
    }

    /** @dev Borrow a specified number of the given asset against the collateral */
    function borrow(IERC20 _collateral, IERC20 _borrowed, uint256 _amount) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        // Requirements for borrowing
        uint256 periodId = pool.currentPeriodId();
        require(_amount > 0, "Amount must be greater than 0");
        require(!pool.isPrologue(periodId) && !pool.isEpilogue(periodId), "Cannot borrow during the prologue or epilogue");
        require(liquidityAvailable(_borrowed) >= _amount, "Amount to borrow exceeds available liquidity");
        require(_collateral != _borrowed, "Cannot borrow against the same asset");

        BorrowPeriod storage borrowPeriod = BorrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        require(borrowAccount.collateral > 0 && borrowAccount.collateral >= minCollateral(_collateral), "Not enough collateral to borrow against");

        if (borrowAccount.borrowed == 0) borrowAccount.initialBorrowTime = block.timestamp;

        _borrowHelper(borrowAccount, borrowPeriod, _collateral, _borrowed, _amount);

        emit Borrow(_msgSender(), periodId, _collateral, _borrowed, _amount);
    }

    /** @dev Get the debt of a given account */
    function debtOf(address _account, IERC20 _collateral, IERC20 _borrowed) external view returns (uint256) {
        // Return the collateral of the account
        uint256 periodId = pool.currentPeriodId();
        BorrowPeriod storage borrowPeriod = BorrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        return borrowAccount.borrowed;
    }

    /** @dev Get the most recent borrow time for a given account */
    function borrowTime(address _account, IERC20 _collateral, IERC20 _borrowed) external view returns (uint256) {
        // Return the collateral of the account
        uint256 periodId = pool.currentPeriodId();
        BorrowPeriod storage borrowPeriod = BorrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        return borrowAccount.borrowTime;
    }

    // ======== Repay and withdraw ========

    function _swap(IERC20 _token1, IERC20 _token2, uint256 _amount) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(_token1);
        path[1] = address(_token2);

        address router = address(oracle.getRouter());
        _token1.safeApprove(address(router), _amount);
        return UniswapV2Router02(router).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp + 1 hours)[1];
    }

    function _balanceHelper(IERC20 _collateral, IERC20 _borrowed, BorrowAccount memory _borrowAccount) private view returns (uint256, uint256) {
        uint256 interest = calculateInterest(_borrowed, _borrowAccount.initialPrice, _borrowAccount.initialBorrowTime);
        uint256 borrowedCurrentPrice = oracle.pairPrice(_borrowed, _collateral).mul(_borrowAccount.borrowed).div(oracle.decimals());
        return (interest, borrowedCurrentPrice);
    }

    /** @dev Check the current margin balance of an account */
    function balanceOf(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _periodId) public view returns (uint256) {
        // The value returned from repaying a margin in terms of the collateral asset
        BorrowAccount storage borrowAccount = BorrowPeriods[_periodId][_borrowed].collateral[_account][_collateral];

        (uint256 interest, uint256 borrowedCurrentPrice) = _balanceHelper(_collateral, _borrowed, borrowAccount);
        if (!pool.isCurrentPeriod(_periodId)) return borrowAccount.collateral.sub(interest);

        return borrowAccount.collateral.add(borrowedCurrentPrice).sub(borrowAccount.initialPrice).sub(interest);
    }

    function _repayGreaterHelper(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _balAfterRepay, BorrowAccount storage _borrowAccount) private {
        // Convert the accounts tokens back to the deposited asset
        uint256 payout = oracle.pairPrice(_collateral, _borrowed).mul(_balAfterRepay.sub(_borrowAccount.collateral)).div(oracle.decimals());

        // Get the amount in borrowed assets that the earned balance is worth and swap them for the given asset
        pool.withdraw(_borrowed, payout);
        uint256 amountOut = _swap(_borrowed, _collateral, payout);

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
        uint256 amountOut = _swap(_collateral, _borrowed, repayAmount);

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

    /** @dev Repay the borrowed amount for the given asset and collateral */
    function repay(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _periodId) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        // If the period has entered the epilogue phase, then anyone may repay the account
        require(_account == _msgSender() || pool.isEpilogue(_periodId) || !pool.isCurrentPeriod(_periodId), "Only the owner may repay before the epilogue period");

        // Repay off the margin and update the users collateral to reflect it
        BorrowPeriod storage borrowPeriod = BorrowPeriods[_periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        require(borrowAccount.borrowed > 0, "No debt to repay");
        require(block.timestamp > borrowAccount.borrowTime + minBorrowLength || pool.isEpilogue(_periodId), "Cannot repay until minimum borrow period is over or epilogue has started");

        uint256 balAfterRepay = balanceOf(_account, _collateral, _borrowed, _periodId);
        if (balAfterRepay > borrowAccount.collateral) _repayGreaterHelper(_account, _collateral, _borrowed, balAfterRepay, borrowAccount);
        else _repayLessEqualHelper(_account, _collateral, _borrowed, balAfterRepay, borrowAccount);

        // Update the borrowed
        borrowAccount.initialPrice = 0;
        borrowPeriod.totalBorrowed = borrowPeriod.totalBorrowed.sub(borrowAccount.borrowed);
        borrowAccount.borrowed = 0;
        emit Repay(_msgSender(), _periodId, _collateral, _borrowed, balAfterRepay);
    }

    /** @dev Withdraw collateral from the account if the account has no debt */
    function withdraw(IERC20 _collateral, IERC20 _borrowed, uint256 _amount, uint256 _periodId) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        // Check that the user does not have any debt
        BorrowPeriod storage borrowPeriod = BorrowPeriods[_periodId][_borrowed];
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

    /** @dev Check if an account is liquidatable */
    function isLiquidatable(address _account, IERC20 _collateral, IERC20 _borrowed) public view returns (bool) {
        return marginLevel(_account, _collateral, _borrowed) <= _minMarginLevel();
    }

    /** @dev Liquidates a users account that is liquidatable / below the minimum margin level */
    function flashLiquidate(address _account, IERC20 _collateral, IERC20 _borrowed) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        // Liquidate an at risk account
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