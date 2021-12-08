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

    modifier isPrologue(bool _isPrologue) {
        if (_isPrologue) {
            require(vPool.isPrologue(), "Can only perform operation during prologue period");
        } else {
            require(!vPool.isPrologue(), "Cannot perform operation during prologue period");
        }
        _;
    }

    modifier isEpilogue(bool _isEpilogue) {
        if (_isEpilogue) {
            require(vPool.isEpilogue(), "Can only perform operation during epilogue period");
        } else {
            require(!vPool.isEpilogue(), "Cannot perform operation during epilogue period");
        }
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

    // **** Due to the need for depositing before borrowing and that the ratio is a bit above 1:1, depositing such a small value is instantly liquidatable. Make a function for the min deposit required
    // **** HUGE NOTE: INSTEAD OF USING THOSE NESTED CALLING I SHOULD JUST USE STORAGE AND SEE IF IT ACTS AS A POINTER FOR CONVENIANCE - CHANGE ALL OVER TO THIS + IMPLEMENT INTERFACE

    // **** LETS JUST USE THESE CALCULATORS AFTER THE CORE IS DONE

    // function marginLevel(address _account, IERC20 _collateral, IERC20 _borrowed) public view approvedOnly(_collateral) approvedOnly(_borrowed) returns (uint256) {
    //     // Get the margin level of an account for the current period
    //     uint256 periodId = vPool.currentPeriodId();

    //     // Get the borrowed period and and borrowed asset data
    //     BorrowPeriod storage borrowPeriod = borrowPeriods[periodId][_borrowed];
    //     BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

    //     // Calculate margin level - if there is none borrowed then return 999
    //     if (borrowAccount.borrowed == 0) return uint256(999).mul(oracle.getDecimals());
    //     else {
    //         uint256 borrowedCurrentPrice = oracle.pairPrice(_borrowed, _collateral).mul(borrowAccount.borrowed).div(oracle.getDecimals());
    //         uint256 borrowedInitialPrice = borrowAccount.initialPrice; // **** This is also probably stored using decimals I believe ????
    //         uint256 interest = calculateInterest(_borrowed, borrowedInitialPrice, block.timestamp - borrowAccount.borrowTime);

    //         return oracle.getDecimals().mul(borrowedCurrentPrice.add(borrowAccount.collateral)).div(borrowedInitialPrice.add(interest));
    //     }
    // }

    // function getMinMarginLevel() public view returns (uint256) {
    //     // Return the minimum margin level before liquidation
    //     return uint256(minMarginLevel).mul(oracle.getDecimals()).div(100);
    // }

    // function calculateInterest(IERC20 _token, uint256 _initialBorrowPrice, uint256 _timeSinceBorrow) public view approvedOnly(_token) returns (uint256) {
    //     // interest = timesAccumulated * priceBorrowedInitially * (totalBorrowed / (totalBorrowed + liquiditiyAvailable))
    //     uint256 periodId = vPool.currentPeriodId();
    //     uint256 totalBorrowed = borrowPeriods[periodId][_token].totalBorrowed;
    //     uint256 liquidity = liquidityAvailable(_token);

    //     return _timeSinceBorrow.mul(_initialBorrowPrice).mul(totalBorrowed).div(interestInterval).div(liquidity.add(totalBorrowed));
    // }

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
        emit Deposit(_msgSender(), _collateral, periodId, _borrow, _amount);
    }

    // ======== Borrow ========

    function borrow(IERC20 _borrow, IERC20 _collateral, uint256 _amount) external approvedOnly(_borrow) approvedOnly(_collateral) isPrologue(false) isEpilogue(false) {
        // Requirements for borrowing
        require(_amount > 0, "Amount must be greater than 0");
        // **** I need to make sure that the borrow cant happen before the epilogue time
        require(liquidityAvailable(_borrow) >= _amount, "Amount to borrow exceeds available liquidity");

        uint256 periodId = vPool.currentPeriodId();
        BorrowPeriod storage borrowPeriod = borrowPeriods[periodId][_borrow];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        require(borrowAccount.collateral > 0, "Must deposit collateral before borrowing");

        // Update the balances of the borrowed value
        borrowPeriod.totalBorrowed = borrowPeriod.totalBorrowed.add(_amount);
        uint256 borrowInitialValue = oracle.pairPrice(_collateral, _borrow).mul(_amount).div(oracle.getDecimals());
        borrowAccount.initialPrice = borrowAccount.initialPrice.add(borrowInitialValue.mul(_amount).div(oracle.getDecimals()));

        // **** THINK ABOUT THE LIQUIDATION LEVEL MORE - DOES IT OCCUR WHEN A BIT OF THE VALUE HAS BEEN LOST AND AS SUCH WE JUST TAKE THE COLLATERAL - IF THIS IS THE CASE THIS NEEDS TO HAPPEN IN OUR REPAY
        // **** So basically at the current time, if the user is in the red but not enough to be liquidated when the next period ends, the protocol is the one who takes the loss - this SHOULD NOT happen - how can I fix this ?
        // **** Maybe flash liquidate should always be callable, but only up to what the user actually owes the protocol - same collateralization rates will occur

        // **** The answer is to have the repay be callable by EVERYONE before the new period happens and stakers can withdraw their amount - the problem was if users couldnt repay, but if they have to this problem doesnt exist. Flash liquidates can still happen though for on the go liquidity

        emit Borrow(_msgSender(), _borrow, periodId, _collateral, _amount);
    }

    // ======== Repay and withdraw ========

    function repayValue() public {

    }

    function repay(address _account) public {
        // **** Use this to repay accounts outside of the given borrow period
    }

    function repay() external {
        // **** Perhaps we need an amount for how much needs to be repaid exactly off of the margin ?
        // Repay off the loan
    }

    function withdraw() external {
        // Make sure that the amount to be repaid is not valid yet
    }

    // ======== Liquidate ========

    function flashLiquidateOwing() external returns (uint256) {
        // This is the amount that is required to be paid back to the protocol - this is NOT the amount that will be actually given off
    }

    function flashLiquidate() external returns (uint256) {
        // In here we consume the requested price if it is present for the given token pair
    }

    // ======== Events ========

    event Deposit(address indexed depositor, IERC20 indexed collateral, uint256 periodId, IERC20 borrow, uint256 amount);
    event Borrow(address indexed borrower, IERC20 indexed borrowed, uint256 periodId, IERC20 collateral, uint256 amount);
    event Repay();
    event Withdraw();
    event FlashLiquidation();
}