//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsolatedMarginLevel.sol";

abstract contract IsolatedMarginCollateral is IsolatedMarginLevel {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
}