//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../FlashSwap/IFlashSwap.sol";
import "./MarginLevel.sol";

abstract contract MarginLiquidate is MarginLevel {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Liquidate an undercollateralized account
    function repay(address account_) external {
        require(isBorrowing(account_), "Cannot repay an account that has not borrowed");
    }

    event Repay(address indexed account, address liquidator);
}