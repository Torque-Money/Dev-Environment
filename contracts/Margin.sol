//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IMargin.sol";
import "./IOracle.sol";
import "./IVPool.sol";
import "./ILiquidator.sol";

contract Margin is IMargin {
    struct Borrow {
        uint256 totalBorrowed;
        mapping(address => uint256) borrowed;
    }
    mapping(uint256 => mapping(uint256 => Borrow)) private borrows;

    address private vPool;
    address private oracle;

    constructor(address vPool_, address oracle_) {
        vPool = vPool_;
        oracle = oracle_;
    }

    // Probably better off to be an oracle function
    function liquidityAvailable() public returns (uint256) {

    }

    // **** First we will need some way of letting people borrow
    function borrow(address _token ) external {

    }

    // **** Then we will need a way of liquidating them according to some margin level

    // **** We will also need a way of quering the margin level, as well as the time left on a borrow and such
}