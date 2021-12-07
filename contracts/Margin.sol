//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IMargin.sol";
import "./IOracle.sol";
import "./IVPool.sol";
import "./ILiquidator.sol";

contract Margin is IMargin {
    struct BorrowPeriod {
        uint256 totalBorrowed;
        mapping(address => uint256) borrowed;
        mapping(address => uint256) collateral;
    }
    mapping(uint256 => mapping(uint256 => Margin)) private borrowPeriods;

    IVPool private vPool;
    IOracle private oracle;

    constructor(IVPool vPool_, IOracle oracle_) {
        vPool = vPool_;
        oracle = oracle_;
    }

    modifier approvedOnly(IERC20 _token) {
        require(vPool.isApproved(_token), "This token has not been approved");
        _;
    }

    // Probably better off to be an oracle function
    function liquidityAvailable() public returns (uint256) {

    }

    function marginLevel() public returns (uint256) {

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

    }

    // ======== Events ========

    event Borrow();
    event Withdraw();
    event FlashLiquidation();
}