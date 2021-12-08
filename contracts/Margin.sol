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
        uint256 borrowTime;
    }
    struct BorrowPeriod {
        uint256 totalBorrowed;
        mapping(address => mapping(IERC20 => BorrowAccount)) collateral; // account => token => borrow - this way the same account can have different borrows with different collaterals independently
    }
    mapping(uint256 => mapping(IERC20 => BorrowPeriod)) private borrowPeriods;
    uint256 private minBorrowPeriod;
    uint256 private minMarginLevel;

    uint256 private interestInterval;

    constructor(IVPool vPool_, IOracle oracle_, uint256 minBorrowPeriod_, uint256 interestInterval_, uint256 minMarginLevel_) {
        vPool = vPool_;
        oracle = oracle_;
        minBorrowPeriod = minBorrowPeriod_;
        interestInterval = interestInterval_;
        minMarginLevel = minMarginLevel_;
    }

    // ======== Modifiers ========

    modifier approvedOnly(IERC20 _token) {
        require(vPool.isApproved(_token), "This token has not been approved");
        _;
    }

    modifier isNotCooldown {
        require(!vPool.isCooldown(), "Cannot perform operation during cooldown");
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

    function marginLevel(address _account, IERC20 _collateral, IERC20 _borrowed) public view approvedOnly(_collateral) approvedOnly(_borrowed) returns (uint256) {
        // Get the margin level of an account for the current period
        uint256 periodId = vPool.currentPeriodId();

        // Get the borrowed period and and borrowed asset data
        BorrowPeriod storage borrowPeriod = borrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        // Calculate margin level - if there is none borrowed then return 999
        if (borrowAccount.borrowed == 0) return uint256(999).mul(oracle.getDecimals());
        else {
            uint256 borrowedCurrentPrice = oracle.pairPrice(_borrowed, _collateral);
            uint256 borrowedInitialPrice = borrowAccount.initialPrice;
            uint256 interest = calculateInterest(_borrowed, borrowAccount.borrowed, block.timestamp - borrowAccount.borrowTime);
            return oracle.getDecimals().mul(borrowedCurrentPrice.add(borrowAccount.collateral)).div(borrowedInitialPrice.add(interest));
        }
    }

    function getMinMarginLevel() public view returns (uint256) {
        // Return the minimum margin level before liquidation
        return uint256(minMarginLevel).mul(oracle.getDecimals()).div(100);
    }

    function calculateInterest(IERC20 _token, uint256 _borrowed, uint256 _time) public view approvedOnly(_token) returns (uint256) {
        // interest = timesAccumulated * amountBorrowed * (totalBorrowed / (totalBorrowed + liquiditiyAvailable))
        uint256 periodId = vPool.currentPeriodId();
        uint256 totalBorrowed = borrowPeriods[periodId][_token].totalBorrowed;
        uint256 liquidity = liquidityAvailable(_token);

        return _time.mul(_borrowed).mul(totalBorrowed).div(interestInterval).div(liquidity.add(totalBorrowed));
    }

    // ======== Deposit ========

    function depositCollateral(IERC20 _collateral, uint256 _amount, IERC20 _borrow) external approvedOnly(_collateral) approvedOnly(_borrow) {
        // Make sure the amount is greater than 0
        require(_amount > 0, "Amount must be greater than 0");

        // Store funds in the account for the given asset they wish to borrow
        _collateral.safeTransferFrom(_msgSender(), address(this), _amount);
        uint256 periodId = vPool.currentPeriodId();

        uint256 collateral = borrowPeriods[periodId][_borrow].collateral[_msgSender()][_collateral].collateral;
        borrowPeriods[periodId][_borrow].collateral[_msgSender()][_collateral].collateral = collateral.add(_amount);
        emit Deposit(_msgSender(), _collateral, periodId, _borrow, _amount);
    }

    // ======== Borrow ========

    function borrow(IERC20 _borrowed, IERC20 _collateral, uint256 _amount) external {
        // Requirements
        require(_amount > 0, "Amount must be greater than 0");
        require(liquidityAvailable(_borrowed) >= _amount, "Amount to borrow exceeds available liquidity");
    }

    // ======== Repay and withdraw ========

    // ======== Liquidate ========

    function flashLiquidateOwing() external returns (uint256) {
        // This is the amount that is required to be paid back to the protocol - this is NOT the amount that will be actually given off
    }

    function flashLiquidate() external returns (uint256) {
        // In here we consume the requested price if it is present for the given token pair
    }

    function repayBorrow() external {
        // Repay off the loan
    }

    function withdrawCollateral() external {
        // Allows a user to withdraw their collateral given that it is not locked in
        // **** Only allowed to withdraw once borrow has been repaid and borrowed amount is 0
    }

    function withdrawProfits() external {
        // Allows users to take their earned funds and get out
    }

    // ======== Events ========

    event Deposit(address indexed depositor, IERC20 indexed collateral, uint256 periodId, IERC20 borrow, uint256 amount); // **** I need some way of doing the periodId ?????
    event Borrow();
    event Repay();
    event Withdraw();
    event FlashLiquidation();
}