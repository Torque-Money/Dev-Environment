//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsoMarginAccount.sol";

abstract contract IsoMarginMargin is IsoMarginAccount {
    using SafeMath for uint256;

    // **** Get the margin levels and such here
}