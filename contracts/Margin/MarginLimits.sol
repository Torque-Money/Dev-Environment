//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./MarginAccount.sol";

abstract contract MarginLimits is Initializable, MarginAccount {
    using SafeMathUpgradeable for uint256;

    uint256 public minCollateralPrice;
    uint256 public maxLeverage;

    function initializeMarginLimits(uint256 minCollateralPrice_, uint256 maxLeverage_) public initializer {
        minCollateralPrice = minCollateralPrice_;
        maxLeverage = maxLeverage_;
    }

    // Set the minimum collateral price
    function setMinCollateralPrice(uint256 minCollateralPrice_) external onlyOwner {
        minCollateralPrice = minCollateralPrice_;
    }

    // Check if an account has sufficient collateral to back a loan
    function sufficientCollateralPrice(address account_) public view returns (bool) {
        return collateralPrice(account_) >= minCollateralPrice;
    }

    // Set the maximum leverage
    function setMaxLeverage(uint256 maxLeverage_) external onlyOwner {
        maxLeverage = maxLeverage_;
    }

    // Check if an account is within the max leverage limit
    function maxLeverageReached(address account_) public view returns (bool) {
        uint256 collateralPrice = collateralPrice(account_);
        uint256 totalInitialBorrowPrice = initialBorrowPrice(account_);

        return (collateralPrice.mul(maxLeverage) < totalInitialBorrowPrice);
    }

    // Check if an account is resettable
    function resettable(address account_) public view returns (bool) {
        return (isBorrowing(account_) && (maxLeverageReached(account_) || !sufficientCollateralPrice(account_)));
    }
}
