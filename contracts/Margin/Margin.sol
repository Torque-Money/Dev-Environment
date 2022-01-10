//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./MarginCollateral.sol";
import "./MarginBorrowers.sol";
import "./MarginBorrowLimit.sol";

abstract contract Margin is MarginCollateral, MarginBorrowers, MarginBorrowLimit {}
