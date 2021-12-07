//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IMargin.sol";
import "./IOracle.sol";
import "./IVPool.sol";
import "./ILiquidator.sol";

contract Margin is IMargin {
    IVPool private vPool;
    IOracle private oracle;

    struct AccountBorrow {
        uint256 collateral;
        uint256 borrowed;
        uint256 borrowTime;
    }
    struct BorrowPeriod {
        uint256 totalBorrowed;
        mapping(address => mapping(address => AccountBorrow)) collateral; // account => token => borrow - this way the same account can have different borrows with different collaterals independently
    }
    mapping(uint256 => mapping(IERC20 => BorrowPeriod)) private borrowPeriods;
    uint256 private minBorrowPeriod;

    uint256 private interestInterval;

    constructor(IVPool vPool_, IOracle oracle_, uint256 minBorrowPeriod_, uint256 interestInterval_) {
        vPool = vPool_;
        oracle = oracle_;
        minBorrowPeriod = minBorrowPeriod_;
        interestInterval = interestInterval_;
    }

    modifier approvedOnly(IERC20 _token) {
        require(vPool.isApproved(_token), "This token has not been approved");
        _;
    }

    function liquidityAvailable(IERC20 _token) public view approvedOnly(_token) returns (uint256) {
        // Calculate the liquidity available for the current token for the current period
        uint256 periodId = vPool.currentPeriodId();

        uint256 liquidity = vPool.getLiquidity(_token, periodId);
        uint256 borrowed = borrowPeriods[periodId][_token].totalBorrowed;

        return liquidity - borrowed;
    }

    function marginLevel(IERC20 _token, address _account) public approvedOnly(_token) returns (uint256) {
        
    }

    function liquidatable(IERC20 _token) public approvedOnly(_token) returns (uint256) {

    }

    function depositCollateral() external {

    }

    function borrow(IERC20 _token) external {

    }

    function interest(IERC20 _token, uint256 _amount, uint256 _time) public returns (uint256) {
        // Needs to compensate for the interval too
    }

    function flashLiquidateOwing() external returns (uint256) {
        // This is the amount that is required to be paid back to the protocol - this is NOT the amount that will be actually given off
    }

    function flashLiquidate() external returns (uint256) {
        // In here we consume the requested price if it is present for the given token pair
    }

    function withdraw() external {
        // Allows users to take their earned funds and get out
    }

    // ======== Events ========

    event Borrow();
    event Withdraw();
    event FlashLiquidation();
}