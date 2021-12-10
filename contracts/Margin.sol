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
    mapping(IVPool => mapping(uint256 => mapping(IERC20 => BorrowPeriod))) private borrowPeriods;
    uint256 private minBorrowPeriod;

    uint256 private minMarginLevel; // Stored as the percentage above equilibrium threshold

    uint256 private maxInterestPercent;

    constructor(IOracle oracle_, uint256 minBorrowPeriod_, uint256 maxInterestPercent_, uint256 minMarginLevel_) {
        oracle = oracle_;
        minBorrowPeriod = minBorrowPeriod_;
        maxInterestPercent = maxInterestPercent_;
        minMarginLevel = minMarginLevel_;
    }

    // ======== Modifiers ========

    modifier approvedOnly(IERC20 _token, IVPool _pool) {
        require(_pool.isApproved(_token), "This token has not been approved");
        _;
    }

    // ======== Calculations ========

    function compensationPercentage() public view override returns (uint256) {
        return minMarginLevel.mul(100).div(minMarginLevel.add(100)).div(2);
    }

    function liquidityAvailable(IERC20 _token, IVPool _pool) public view override approvedOnly(_token, _pool) returns (uint256) {
        // Calculate the liquidity available for the current token for the current period
        uint256 periodId = _pool.currentPeriodId();

        uint256 liquidity = _pool.getLiquidity(_token, periodId);
        uint256 borrowed = borrowPeriods[_pool][periodId][_token].totalBorrowed;

        return liquidity - borrowed;
    }

    function calculateMarginLevel(uint256 _deposited, uint256 _initialBorrowPrice, uint256 _borrowTime, uint256 _amountBorrowed, IERC20 _collateral, IERC20 _borrowed, IVPool _pool) public view override approvedOnly(_collateral, _pool) approvedOnly(_borrowed, _pool) returns (uint256) {
        uint256 currentBorrowPrice = oracle.pairPrice(_borrowed, _collateral).mul(_amountBorrowed).div(oracle.getDecimals());
        uint256 interest = calculateInterest(_borrowed, _initialBorrowPrice, _borrowTime, _pool);
        if (_amountBorrowed == 0) return 2 ** 256 - 1;
        return oracle.getDecimals().mul(_deposited.add(currentBorrowPrice)).div(_initialBorrowPrice.add(interest));
    }

    function getMinMarginLevel() public view override returns (uint256) {
        // Return the minimum margin level before liquidation
        return minMarginLevel.add(100).mul(oracle.getDecimals()).div(100);
    }

    function getMarginLevel(address _account, IERC20 _collateral, IERC20 _borrowed, IVPool _pool) public view override approvedOnly(_collateral, _pool) approvedOnly(_borrowed, _pool) returns (uint256) {
        // Get the margin level of an account for the current period
        uint256 periodId = _pool.currentPeriodId();

        // Get the borrowed period and and borrowed asset data
        BorrowPeriod storage borrowPeriod = borrowPeriods[_pool][periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        // Calculate and return accounts margin level
        return calculateMarginLevel(borrowAccount.collateral, borrowAccount.initialPrice, borrowAccount.initialBorrowTime, borrowAccount.borrowed, _borrowed, _collateral, _pool);
    }

    function calculateInterestRate(IERC20 _borrowed, IVPool _pool) public view override approvedOnly(_borrowed, _pool) returns (uint256) {
        // Calculate the interest rate for a given asset
        // interest = totalBorrowed / (totalBorrowed + liquidity)
        uint256 periodId = _pool.currentPeriodId();

        uint256 totalBorrowed = borrowPeriods[_pool][periodId][_borrowed].totalBorrowed;
        uint256 liquidity = liquidityAvailable(_borrowed, _pool);

        return totalBorrowed.mul(oracle.getDecimals()).div(liquidity.add(totalBorrowed));
    }

    function calculateInterest(IERC20 _borrowed, uint256 _initialBorrow, uint256 _borrowTime, IVPool _pool) public view override returns (uint256) {
        // interest = maxInterestPercent * priceBorrowedInitially * interestRate * (timeBorrowed / interestPeriod)
        uint256 periodId = _pool.currentPeriodId();

        uint256 interestRate = calculateInterestRate(_borrowed, _pool);

        uint256 current = block.timestamp;
        (,uint256 prologueEnd) = _pool.getPrologueTimes(periodId);
        (uint256 epilogueStart,) = _pool.getEpilogueTimes(periodId);
        uint256 timeFrame = epilogueStart - prologueEnd;

        return _initialBorrow.mul(maxInterestPercent).mul(interestRate).mul(current.sub(_borrowTime)).div(timeFrame).div(oracle.getDecimals()).div(100);
    }

    // ======== Deposit ========

    function deposit(IERC20 _collateral, IERC20 _borrowed, uint256 _amount, IVPool _pool) external override approvedOnly(_collateral, _pool) approvedOnly(_borrowed, _pool) {
        // Make sure the amount is greater than 0
        require(_amount > 0, "Amount must be greater than 0");

        // Store funds in the account for the given asset they wish to borrow
        _collateral.safeTransferFrom(_msgSender(), address(this), _amount);
        uint256 periodId = _pool.currentPeriodId();

        BorrowPeriod storage borrowPeriod = borrowPeriods[_pool][periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        borrowAccount.collateral = borrowAccount.collateral.add(_amount);
        emit Deposit(_msgSender(), periodId, _pool, _collateral, _borrowed, _amount);
    }

    function redeposit(address _account) public {
        // Redeposit the margin balance from one period to the next
    }

    function redeposit() external {

    }

    // ======== Borrow ========

    function borrow(IERC20 _collateral, IERC20 _borrowed, uint256 _amount, IVPool _pool) external override approvedOnly(_collateral, _pool) approvedOnly(_borrowed, _pool) {
        // Requirements for borrowing
        uint256 periodId = _pool.currentPeriodId();
        require(_amount > 0, "Amount must be greater than 0");
        require(!_pool.isPrologue(periodId), "Cannot borrow during prologue");
        (uint256 epilogueStart,) = _pool.getEpilogueTimes(periodId);
        require(block.timestamp < epilogueStart.sub(minBorrowPeriod), "Minimum borrow period may not overlap with epilogue");
        require(liquidityAvailable(_borrowed, _pool) >= _amount, "Amount to borrow exceeds available liquidity");

        BorrowPeriod storage borrowPeriod = borrowPeriods[_pool][periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        if (borrowAccount.borrowed == 0) {
            borrowAccount.initialBorrowTime = block.timestamp;
        }

        // Require that the borrowed amount will be above the required margin level
        uint256 borrowInitialPrice = oracle.pairPrice(_borrowed, _collateral).mul(_amount).div(oracle.getDecimals());
        require(calculateMarginLevel(borrowAccount.collateral, borrowAccount.initialPrice.add(borrowInitialPrice), borrowAccount.initialBorrowTime, borrowAccount.borrowed.add(_amount), _collateral, _borrowed, _pool) > getMinMarginLevel(), "This deposited amount is not enough to exceed minimum margin level");

        // Update the balances of the borrowed value
        borrowPeriod.totalBorrowed = borrowPeriod.totalBorrowed.add(_amount);

        borrowAccount.initialPrice = borrowAccount.initialPrice.add(borrowInitialPrice);
        borrowAccount.borrowed = borrowAccount.borrowed.add(_amount);
        borrowAccount.borrowTime = block.timestamp;

        emit Borrow(_msgSender(), periodId, _pool, _collateral, _borrowed, _amount);
    }

    // ======== Repay and withdraw ========

    function balanceOf(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _periodId, IVPool _pool) public view override approvedOnly(_collateral, _pool) approvedOnly(_borrowed, _pool) returns (uint256) {
        // The value returned from repaying a margin in terms of the deposited asset
        BorrowPeriod storage borrowPeriod = borrowPeriods[_pool][_periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        uint256 collateral = borrowAccount.collateral;
        if (!_pool.isCurrentPeriod(_periodId)) return collateral;
        uint256 interest = calculateInterest(_borrowed, borrowAccount.initialPrice, borrowAccount.initialBorrowTime, _pool);
        uint256 borrowedCurrentPrice = oracle.pairPrice(_borrowed, _collateral).mul(borrowAccount.borrowed).div(oracle.getDecimals());

        return collateral.add(borrowedCurrentPrice).sub(borrowAccount.initialPrice).sub(interest);
    }

    function repay(address _account, IERC20 _collateral, IERC20 _borrowed, IVPool _pool) public override approvedOnly(_collateral, _pool) approvedOnly(_borrowed, _pool) {
        // If the period has entered the epilogue phase, then anyone may repay the account
        uint256 periodId = _pool.currentPeriodId();
        require(_account == _msgSender() || _pool.isEpilogue(periodId), "Only the owner may repay before the epilogue period");

        // Repay off the margin and update the users collateral to reflect it
        BorrowPeriod storage borrowPeriod = borrowPeriods[_pool][periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        require(borrowAccount.borrowed > 0, "No debt to repay");
        require(block.timestamp > borrowAccount.borrowTime + minBorrowPeriod, "Cannot repay until minimum borrow period is over");

        UniswapV2Router02 router = UniswapV2Router02(oracle.getRouter());
        address[] memory path = new address[](2);
        uint256 deadline = block.timestamp + 1 hours;

        uint256 balAfterRepay = balanceOf(_account, _collateral, _borrowed, periodId, _pool);
        if (balAfterRepay > borrowAccount.collateral) {
            // Convert the accounts tokens back to the deposited asset
            uint256 payoutAmount = balAfterRepay.sub(borrowAccount.collateral);
            uint256 payout = oracle.pairPrice(_collateral, _borrowed).mul(payoutAmount).div(oracle.getDecimals());

            // Get the amount in borrowed assets that the earned balance is worth and swap them for the given asset
            _pool.withdraw(_borrowed, payout);
            path[0] = address(_borrowed);
            path[1] = address(_collateral);
            uint256 amountOut = router.swapExactTokensForTokens(payout, 0, path, address(this), deadline)[1];

            // Provide a reward to the user who repayed the account if they are not the account owner
            uint256 reward = 0;
            if (_account != _msgSender()) {
                reward = amountOut.mul(compensationPercentage()).div(100);
                _collateral.safeTransfer(_msgSender(), reward);
            }

            // Update the balance of the user
            borrowAccount.collateral = borrowAccount.collateral.add(amountOut.sub(reward));

        } else {
            // Amount the user has to repay the protocol
            uint256 repayAmount = borrowAccount.collateral.sub(balAfterRepay);
            borrowAccount.collateral = balAfterRepay;

            // Swap the repay value back for the borrowed asset
            path[0] = address(_collateral);
            path[1] = address(_borrowed);
            uint256 amountOut = router.swapExactTokensForTokens(repayAmount, 0, path, address(this), deadline)[1];

            // Provide a reward to the user who repayed the account if they are not the account owner
            uint256 reward = 0;
            if (_account != _msgSender()) {
                reward = amountOut.mul(compensationPercentage()).div(100);
                _borrowed.safeTransfer(_msgSender(), reward);
            }

            // Return the assets back to the pool
            uint256 depositValue = amountOut.sub(reward);
            _borrowed.safeApprove(address(_pool), depositValue);
            _pool.deposit(_borrowed, depositValue);
        }

        // Update the borrowed
        borrowAccount.initialPrice = 0;
        borrowPeriod.totalBorrowed = borrowPeriod.totalBorrowed.sub(borrowAccount.borrowed);
        borrowAccount.borrowed = 0;
        emit Repay(_msgSender(), periodId, _pool, _collateral, _borrowed, balAfterRepay);
    }

    function repay(IERC20 _collateral, IERC20 _borrowed, IVPool _pool) external override {
        // Repay off the loan for the caller
        repay(_msgSender(), _collateral, _borrowed, _pool);
    }

    function withdraw(IERC20 _collateral, IERC20 _borrowed, uint256 _periodId, uint256 _amount, IVPool _pool) external override approvedOnly(_collateral, _pool) approvedOnly(_borrowed, _pool) {
        // Check that the user does not have any debt
        BorrowPeriod storage borrowPeriod = borrowPeriods[_pool][_periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        // Require the amount in the balance and the user not to be borrowing
        require(borrowAccount.borrowed == 0, "Cannot withdraw with outstanding debt, repay first");
        require(borrowAccount.collateral >= _amount, "Insufficient balance to withdraw");

        // Update the balance and transfer
        borrowAccount.collateral = borrowAccount.collateral.sub(_amount);
        _collateral.safeTransfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _periodId, _pool, _collateral, _borrowed, _amount);
    }

    // ======== Liquidate ========

    function isLiquidatable(address _account, IERC20 _borrowed, IERC20 _collateral, IVPool _pool) public view override returns (bool) {
        // Return if a given account is liquidatable
        return getMarginLevel(_account, _collateral, _borrowed, _pool) <= getMinMarginLevel(); 
    }

    function flashLiquidate(address _account, IERC20 _borrowed, IERC20 _collateral, IVPool _pool) external override {
        // Liquidate an at risk account
        uint256 periodId = _pool.currentPeriodId();
        require(isLiquidatable(_account, _borrowed, _collateral, _pool), "This account is not liquidatable");

        BorrowPeriod storage borrowPeriod = borrowPeriods[_pool][periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        // Update the users account
        uint256 collateral = borrowAccount.collateral;

        borrowAccount.collateral = 0;
        borrowPeriod.totalBorrowed = borrowPeriod.totalBorrowed.sub(borrowAccount.borrowed);
        borrowAccount.borrowed = 0;
        borrowAccount.initialPrice = 0;

        // Swap the users collateral for assets
        UniswapV2Router02 router = UniswapV2Router02(oracle.getRouter());
        address[] memory path = new address[](2);
        uint256 deadline = block.timestamp + 1 hours;

        path[0] = address(_collateral);
        path[1] = address(_borrowed);

        uint256 amountOut = router.swapExactTokensForTokens(collateral, 0, path, address(this), deadline)[1];

        // Compensate the liquidator
        uint256 reward = amountOut.mul(compensationPercentage()).div(100);
        _borrowed.safeTransfer(_msgSender(), reward);
        uint256 depositValue = amountOut.sub(reward);
        _borrowed.safeApprove(address(_pool), depositValue);
        _pool.deposit(_borrowed, depositValue);

        emit FlashLiquidation(_account, periodId, _pool, _msgSender(), _collateral, _borrowed, collateral);
    }
}