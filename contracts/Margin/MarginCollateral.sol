//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginBorrow.sol";
import "./MarginLevel.sol";

abstract contract MarginCollateral is MarginBorrow, MarginLevel {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Deposit collateral into the account
    function addCollateral(IERC20 collateral_, uint256 amount_) external onlyApprovedCollateral {
        collateral_.safeTransferFrom(_msgSender(), address(this), amount_);
        _setCollateral(collateral_, collateral(collateral_, _msgSender()).add(amount_), _msgSender());
        emit AddCollateral(_msgSender(), collateral, amount_);
    }

    // Withdraw collateral from the account
    function removeCollateral(IERC20 collateral_, uint256 amount_) external {
        uint256 currentCollateral = collateral(collateral_, _msgSender());
        require(amount_ <= currentCollateral, "Cannot remove more than available collateral");

        _setCollateral(collateral_, collateral(collateral_, _msgSender()).sub(amount_), _msgSender());
        require(!underCollateralized(_msgSender()), "Removing collateral results in an undercollateralized account");
        require(
            borrowedPrice(account_) == 0 || collateralPrice(account_) >= minCollateralPrice,
            "Cannot withdraw if new collateral price is less than minimum borrow price whilst borrowing"
        );

        collateral_.safeTransfer(_msgSender(), amount_);
        emit RemoveCollateral(_msgSender(), collateral_, amount_);
    }

    event AddCollateral(address indexed account, IERC20 collateral, uint256 amount);
    event RemoveCollateral(address indexed account, IERC20 collateral, uint256 amount);
}