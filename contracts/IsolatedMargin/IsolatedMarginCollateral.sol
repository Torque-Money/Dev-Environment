//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsolatedMarginLevel.sol";

abstract contract IsolatedMarginCollateral is IsolatedMarginLevel {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Deposit collateral into the specified account
    function depositCollateral(IERC20 borrowed_, IERC20 collateral_, uint256 amount_) external onlyLPOrApprovedToken(collateral_) onlyApprovedToken(borrowed_) {
        collateral_.safeTransferFrom(_msgSender(), address(this), amount_);
        _setCollateral(borrowed_, collateral_, amount_, _msgSender());
        emit DepositCollateral(_msgSender(), borrowed_, collateral_, amount_);
    }

    event DepositCollateral(address indexed account, IERC20 borrowed, IERC20 collateral, uint256 amount);
}