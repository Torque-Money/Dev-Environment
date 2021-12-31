//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../Oracle/Oracle.sol";
import "../FlashSwap/FlashSwap.sol";
import "../LPool/LPool.sol";
import "./MarginApproved.sol";
import "./MarginPool.sol";

abstract contract Margin is MarginApproved, MarginPool {}