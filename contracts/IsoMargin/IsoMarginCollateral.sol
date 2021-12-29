//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsoMarginAccount.sol";

abstract contract IsoMarginCollateral is IsoMarginAccount {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Add collateral to the account for the specified asset to borrow against
    function addCollateral(IERC20 collateral_, IERC20 borrowed_, uint256 amount_) external onlyLPOrApprovedToken(collateral_) onlyApprovedToken(borrowed_) {
        collateral_.safeTransferFrom(_msgSender(), address(this), amount_);
        _setCollateral(collateral_, borrowed_, collateral(collateral_, borrowed_, _msgSender()).add(amount_));
        emit AddedCollateral(_msgSender(), collateral_, borrowed_, amount_);
    }

    // Withdraw collateral from the given margin account
    function withdrawCollateral(IERC20 collateral_, IERC20 borrowed_, uint256 amount_) external {
        
    }

    event AddedCollateral(address indexed account, IERC20 collateral, IERC20 borrowed, uint256 amount);
    event WithdrawCollateral(address indexed account, IERC20 collateral, IERC20 borrowed, uint256 amount);
}