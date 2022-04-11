//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {MarginAccount} from "./MarginAccount.sol";

abstract contract MarginLimits is Initializable, MarginAccount {
    uint256 public minCollateralPrice;

    function initializeMarginLimits(uint256 minCollateralPrice_) public initializer {
        minCollateralPrice = minCollateralPrice_;
    }

    // Set the minimum collateral price
    function setMinCollateralPrice(uint256 minCollateralPrice_) external onlyRole(MARGIN_ADMIN) {
        minCollateralPrice = minCollateralPrice_;
    }

    // Check if an account has sufficient collateral to leverage
    function _sufficientCollateralPrice(address account_) internal view returns (bool) {
        return collateralPrice(account_) >= minCollateralPrice;
    }

    // Check if an account is resettable
    function resettable(address account_) public view returns (bool) {
        return (_isBorrowing(account_) && !_sufficientCollateralPrice(account_));
    }
}
