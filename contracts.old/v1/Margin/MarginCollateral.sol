//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./MarginLevel.sol";
import "./MarginApproved.sol";
import "./MarginLimits.sol";

abstract contract MarginCollateral is MarginApproved, MarginLevel, MarginLimits {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Deposit collateral into the account
    function addCollateral(address token_, uint256 amount_) external onlyApprovedCollateralToken(token_) {
        require(amount_ > 0, "MarginCollateral: Amount added as collateral must be greater than 0");

        IERC20Upgradeable(token_).safeTransferFrom(_msgSender(), address(this), amount_);
        _setCollateral(token_, collateral(token_, _msgSender()).add(amount_), _msgSender());

        emit AddCollateral(_msgSender(), token_, amount_);
    }

    // Withdraw collateral from the account
    function removeCollateral(address token_, uint256 amount_) external onlyCollateralToken(token_) {
        require(amount_ > 0, "MarginCollateral: Collateral amount removed must be greater than 0");
        require(amount_ <= collateral(token_, _msgSender()), "MarginCollateral: Cannot remove more than available collateral");

        _setCollateral(token_, collateral(token_, _msgSender()).sub(amount_), _msgSender());
        require(!resettable(_msgSender()) && !liquidatable(_msgSender()), "MarginCollateral: Withdrawing desired collateral puts account at risk");

        IERC20Upgradeable(token_).safeTransfer(_msgSender(), amount_);

        emit RemoveCollateral(_msgSender(), token_, amount_);
    }

    event AddCollateral(address indexed account, address token, uint256 amount);
    event RemoveCollateral(address indexed account, address token, uint256 amount);
}
