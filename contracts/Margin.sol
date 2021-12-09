//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IMargin.sol";
import "./IOracle.sol";
import "./IVPool.sol";
import "./ILiquidator.sol";
import "./lib/UniswapV2Router02.sol";

// **** Perhaps the Margin will be independent of the pool, and users may choose which pool they wish to use at runtime

contract Margin is IMargin, Context {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IVPool private vPool;
    IOracle private oracle;

    struct BorrowAccount {
        uint256 collateral;
        uint256 borrowed;
        uint256 initialPrice;
    }
    struct BorrowPeriod {
        uint256 totalBorrowed;
        mapping(address => mapping(IERC20 => BorrowAccount)) collateral; // account => token => borrow - this way the same account can have different borrows with different collaterals independently
    }
    mapping(uint256 => mapping(IERC20 => BorrowPeriod)) private borrowPeriods;
    uint256 private minBorrowPeriod;
    uint256 private minMarginLevel; // **** Hangon, this is actually the same thing that should control the amount that the others get rewarded too - we will take just enough to make profit off of liquidators and the rest to stakers

    uint256 private maxInterestPercent;

    uint256 private automatorReward;

    constructor(IVPool vPool_, IOracle oracle_, uint256 minBorrowPeriod_, uint256 maxInterestPercent_, uint256 minMarginLevel_, uint256 automatorReward_) {
        vPool = vPool_;
        oracle = oracle_;
        minBorrowPeriod = minBorrowPeriod_;
        maxInterestPercent = maxInterestPercent_;
        minMarginLevel = minMarginLevel_;
        automatorReward = automatorReward_;
    }

    // ======== Modifiers ========

    modifier approvedOnly(IERC20 _token) {
        require(vPool.isApproved(_token), "This token has not been approved");
        _;
    }

    // ======== Calculations ========

    function liquidityAvailable(IERC20 _token) public view approvedOnly(_token) returns (uint256) {
        // Calculate the liquidity available for the current token for the current period
        uint256 periodId = vPool.currentPeriodId();

        uint256 liquidity = vPool.getLiquidity(_token, periodId);
        uint256 borrowed = borrowPeriods[periodId][_token].totalBorrowed;

        return liquidity - borrowed;
    }

    function calculateMarginLevel(uint256 _deposited, uint256 _initialBorrowPrice, uint256 _amountBorrowed, IERC20 _borrowed, IERC20 _collateral) public view approvedOnly(_borrowed) approvedOnly(_collateral) returns (uint256) {
        uint256 currentBorrowPrice = oracle.pairPrice(_borrowed, _collateral).mul(_amountBorrowed).div(oracle.getDecimals());
        uint256 interest = calculateInterest(_borrowed, _initialBorrowPrice);
        if (_amountBorrowed == 0) return 2 ** 256 - 1;
        return oracle.getDecimals().mul(_deposited.add(currentBorrowPrice)).div(_initialBorrowPrice.add(interest));
    }

    function getMinMarginLevel() public view returns (uint256) {
        // Return the minimum margin level before liquidation
        return uint256(minMarginLevel).mul(oracle.getDecimals()).div(100);
    }

    function getMarginLevel(address _account, IERC20 _collateral, IERC20 _borrowed) public view approvedOnly(_collateral) approvedOnly(_borrowed) returns (uint256) {
        // Get the margin level of an account for the current period
        uint256 periodId = vPool.currentPeriodId();

        // Get the borrowed period and and borrowed asset data
        BorrowPeriod storage borrowPeriod = borrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        // Calculate and return accounts margin level
        return calculateMarginLevel(borrowAccount.collateral, borrowAccount.initialPrice, borrowAccount.borrowed, _borrowed, _collateral);
    }

    function calculateInterest(IERC20 _borrowed, uint256 _initialBorrow) public view approvedOnly(_borrowed) returns (uint256) {
        // interest = maxInterestPercent * priceBorrowedInitially * (totalBorrowed / (totalBorrowed + liquiditiyAvailable))
        uint256 periodId = vPool.currentPeriodId();

        uint256 totalBorrowed = borrowPeriods[periodId][_borrowed].totalBorrowed;
        uint256 liquidity = liquidityAvailable(_borrowed);

        return _initialBorrow.mul(maxInterestPercent).mul(totalBorrowed).div(totalBorrowed.add(liquidity)).div(100);
    }

    // ======== Deposit ========

    function deposit(IERC20 _collateral, uint256 _amount, IERC20 _borrow) external approvedOnly(_collateral) approvedOnly(_borrow) {
        // Make sure the amount is greater than 0
        require(_amount > 0, "Amount must be greater than 0");

        // Store funds in the account for the given asset they wish to borrow
        _collateral.safeTransferFrom(_msgSender(), address(this), _amount);
        uint256 periodId = vPool.currentPeriodId();

        BorrowPeriod storage borrowPeriod = borrowPeriods[periodId][_borrow];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        borrowAccount.collateral = borrowAccount.collateral.add(_amount);
        emit Deposit(periodId, _borrow, _collateral, _msgSender(), _amount);
    }

    // ======== Borrow ========

    function borrow(IERC20 _borrow, IERC20 _collateral, uint256 _amount) external approvedOnly(_borrow) approvedOnly(_collateral) {
        // Requirements for borrowing
        uint256 periodId = vPool.currentPeriodId();
        require(_amount > 0, "Amount must be greater than 0");
        require(!vPool.isPrologue(periodId), "Cannot borrow during prologue");
        (uint256 epilogueStart,) = vPool.getEpilogueTimes(periodId);
        require(block.timestamp < epilogueStart.sub(minBorrowPeriod), "Minimum borrow period may not overlap with epilogue");
        require(liquidityAvailable(_borrow) >= _amount, "Amount to borrow exceeds available liquidity");

        BorrowPeriod storage borrowPeriod = borrowPeriods[periodId][_borrow];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        // Require that the borrowed amount will be above the required margin level
        uint256 borrowInitialPrice = oracle.pairPrice(_borrow, _collateral).mul(_amount).div(oracle.getDecimals());
        require(calculateMarginLevel(borrowAccount.collateral, borrowInitialPrice, _amount, _borrow, _collateral) > getMinMarginLevel(), "This deposited amount is not enough to exceed minimum margin level");

        // Update the balances of the borrowed value
        borrowPeriod.totalBorrowed = borrowPeriod.totalBorrowed.add(_amount);

        borrowAccount.initialPrice = borrowAccount.initialPrice.add(borrowInitialPrice);
        borrowAccount.borrowed = borrowAccount.borrowed.add(_amount);

        emit Borrow(periodId, _borrow, _collateral, _msgSender(), _amount);
    }

    // ======== Repay and withdraw ========

    function balance(address _account, IERC20 _collateral, IERC20 _borrow, uint256 _periodId) public view approvedOnly(_collateral) approvedOnly(_borrow) returns (uint256) {
        // The value returned from repaying a margin in terms of the deposited asset
        BorrowPeriod storage borrowPeriod = borrowPeriods[_periodId][_borrow];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        uint256 collateral = borrowAccount.collateral;
        uint256 interest = calculateInterest(_borrow, borrowAccount.initialPrice);
        uint256 borrowedCurrentPrice = oracle.pairPrice(_borrow, _collateral).mul(borrowAccount.borrowed).div(oracle.getDecimals());

        return collateral.add(borrowedCurrentPrice).sub(borrowAccount.initialPrice).sub(interest);
    }

    function repay(address _account, IERC20 _collateral, IERC20 _borrow) public approvedOnly(_collateral) approvedOnly(_borrow) {
        // If the period has entered the epilogue phase, then anyone may repay the account
        uint256 periodId = vPool.currentPeriodId();
        require(_account == _msgSender() || vPool.isEpilogue(periodId), "Only the owner may repay before the epilogue period");

        // Repay off the margin and update the users collateral to reflect it
        BorrowPeriod storage borrowPeriod = borrowPeriods[periodId][_borrow];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        require(borrowAccount.borrowed > 0, "No debt to repay");

        UniswapV2Router02 router = UniswapV2Router02(oracle.getRouter());
        address[] memory path = new address[](2);
        uint256 deadline = block.timestamp + 1 hours;

        uint256 balAfterRepay = balance(_account, _collateral, _borrow, periodId);
        if (balAfterRepay > borrowAccount.collateral) {
            // Convert the accounts tokens back to the deposited asset
            uint256 payoutAmount = balAfterRepay.sub(borrowAccount.collateral);
            uint256 payout = oracle.pairPrice(_collateral, _borrow).mul(payoutAmount).div(oracle.getDecimals());

            // Get the amount in borrowed assets that the earned balance is worth and swap them for the given asset
            vPool.withdraw(_borrow, payout);
            path[0] = address(_borrow);
            path[1] = address(_collateral);
            uint256 amountOut = router.swapExactTokensForTokens(payout, 0, path, address(this), deadline)[1];

            // Provide a reward to the user who repayed the account if they are not the account owner
            uint256 reward = 0;
            if (_account != _msgSender()) {
                reward = amountOut.mul(automatorReward).div(100);
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
            path[1] = address(_borrow);
            uint256 amountOut = router.swapExactTokensForTokens(repayAmount, 0, path, address(this), deadline)[1];

            // Provide a reward to the user who repayed the account if they are not the account owner
            uint256 reward = 0;
            if (_account != _msgSender()) {
                reward = amountOut.mul(automatorReward).div(100);
                _borrow.safeTransfer(_msgSender(), reward);
            }

            // Return the assets back to the pool
            uint256 depositValue = amountOut.sub(reward);
            _borrow.safeApprove(address(vPool), depositValue);
            vPool.deposit(_borrow, depositValue);
        }

        // Update the borrowed
        borrowAccount.initialPrice = 0;
        borrowPeriod.totalBorrowed = borrowPeriod.totalBorrowed.sub(borrowAccount.borrowed);
        borrowAccount.borrowed = 0;
        emit Repay(periodId, _borrow, _collateral, _msgSender());
    }

    function repay(IERC20 _collateral, IERC20 _borrow) external {
        // Repay off the loan for the caller
        repay(_msgSender(), _collateral, _borrow);
    }

    function withdraw(IERC20 _collateral, IERC20 _borrow, uint256 _periodId, uint256 _amount) external {
        // Check that the user does not have any debt
        BorrowPeriod storage borrowPeriod = borrowPeriods[_periodId][_borrow];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        // Require the amount in the balance and the user not to be borrowing
        require(borrowAccount.borrowed == 0, "Cannot withdraw with outstanding debt, repay first");
        require(borrowAccount.collateral >= _amount, "Insufficient balance to withdraw");

        // Update the balance and transfer
        borrowAccount.collateral = borrowAccount.collateral.sub(_amount);
        _collateral.safeTransfer(_msgSender(), _amount);
        emit Withdraw(_periodId, _borrow, _collateral, _msgSender());
    }

    // ======== Liquidate ========

    function flashLiquidate() external {
        // In here we consume the requested price if it is present for the given token pair
    }

    // ======== Events ========

    event Deposit(address indexed account, uint256 indexed periodId, IERC20 borrowed, IERC20 collateral, uint256 amount);
    event Withdraw(address indexed account, uint256 indexed periodId, IERC20 borrowed, IERC20 collateral);

    event Borrow(address indexed account, uint256 indexed periodId, IERC20 borrowed, IERC20 collateral, uint256 amount);
    event Repay(address indexed account, uint256 indexed periodId, IERC20 borrowed, IERC20 collateral);

    event FlashLiquidation();
}