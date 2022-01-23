//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginLevel.sol";
import "./MarginApproved.sol";
import "./MarginLimits.sol";

import "hardhat/console.sol";

abstract contract MarginCollateral is MarginApproved, MarginLevel, MarginLimits {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Deposit collateral into the account
    function addCollateral(IERC20 collateral_, uint256 amount_) external onlyApprovedCollateral(collateral_) {
        collateral_.safeTransferFrom(_msgSender(), address(this), amount_);
        _setCollateral(collateral_, collateral(collateral_, _msgSender()).add(amount_), _msgSender());

        emit AddCollateral(_msgSender(), collateral_, amount_);
    }

    // Withdraw collateral from the account
    function removeCollateral(IERC20 collateral_, uint256 amount_) external {
        require(amount_ <= collateral(collateral_, _msgSender()), "MarginCollateral: Cannot remove more than available collateral");

        _setCollateral(collateral_, collateral(collateral_, _msgSender()).sub(amount_), _msgSender());

        console.log(isBorrowing(_msgSender()));
        console.log(resettable(_msgSender()));
        console.log(liquidatable(_msgSender()));

        require(!resettable(_msgSender()) && !liquidatable(_msgSender()), "MarginCollateral: Withdrawing desired collateral puts account at risk");

        collateral_.safeTransfer(_msgSender(), amount_);

        emit RemoveCollateral(_msgSender(), collateral_, amount_);
    }

    event AddCollateral(address indexed account, IERC20 collateral, uint256 amount);
    event RemoveCollateral(address indexed account, IERC20 collateral, uint256 amount);
}
