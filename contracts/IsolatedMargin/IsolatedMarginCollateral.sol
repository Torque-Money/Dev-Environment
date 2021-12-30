//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsolatedMarginBorrow.sol";

abstract contract IsolatedMarginCollateral is IsolatedMarginBorrow {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Deposit collateral into the specified account
    function depositCollateral(IERC20 borrowed_, IERC20 collateral_, uint256 amount_) external onlyLPOrApprovedToken(collateral_) onlyApprovedToken(borrowed_) {
        collateral_.safeTransferFrom(_msgSender(), address(this), amount_);
        _setCollateral(borrowed_, collateral_, amount_, _msgSender());
        emit DepositCollateral(_msgSender(), borrowed_, collateral_, amount_);
    }

    // Withdraw the specified amount of collateral
    function withdrawCollateral(IERC20 borrowed_, IERC20 collateral_, uint256 amount_) external {
        uint256 currentCollateral = collateral(borrowed_, collateral_, _msgSender());
        require(amount_ <= currentCollateral, "Not enough collateral to withdraw");

        _setCollateral(borrowed_, collateral_, collateral(borrowed_, collateral_, _msgSender()).sub(amount_), _msgSender());
        require(!underCollateralized(borrowed_, _msgSender()), "Cannot withdraw an amount that results in an undercollateralized borrow");
        require(borrowed(borrowed_, _msgSender()) == 0 || collateralPrice(borrowed_, _msgSender()) >= minMarginLevel,
                "Whilst borrowing collateral price must be greater than minimum");

        collateral_.safeTransfer(_msgSender(), amount_);
        emit WithdrawCollateral(_msgSender(), borrowed_, collateral_, amount_);
    }

    event DepositCollateral(address indexed account, IERC20 borrowed, IERC20 collateral, uint256 amount);
    event WithdrawCollateral(address indexed account, IERC20 borrowed, IERC20 collateral, uint256 amount);
}