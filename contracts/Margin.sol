//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IMargin.sol";
import "./ILiquidator.sol";
import "./IOracle.sol";

contract Margin is IMargin {
    struct Borrow {

    }
    mapping(uint256 => mapping(uint256 => Borrow)) private borrows;

    // **** First we will need some way of letting people borrow

    // **** Then we will need a way of liquidating them according to some margin level

    // **** We will also need a way of quering the margin level, as well as the time left on a borrow and such
}