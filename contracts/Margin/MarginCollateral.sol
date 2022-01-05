//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginBorrow.sol";

abstract contract MarginCollateral is MarginBorrow {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Deposit collateral into the account

    // Withdraw collateral from the account
}