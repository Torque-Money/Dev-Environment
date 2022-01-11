//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginAccount.sol";

abstract contract MarginLimits is MarginAccount {
    using SafeMath for uint256;

    uint256 public minCollateralPrice;
    uint256 public maxLeverage;

    constructor(uint256 minCollateralPrice_, uint256 maxLeverage_) {
        minCollateralPrice = minCollateralPrice_;
        maxLeverage = maxLeverage_;
    }

    // Set the minimum collateral price
    function setMinCollateralPrice(uint256 minCollateralPrice_) external onlyOwner {
        minCollateralPrice = minCollateralPrice_;
    }

    // Set the maximum leverage
    function setMaxLeverage(uint256 maxLeverage_) external onlyOwner {
        maxLeverage = maxLeverage_;
    }

    // Check if an account is within the max leverage limit
    function maxLeverageReached(address account_) public view returns (bool) {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        uint256 collateralPrice = collateralPrice(account_);
        uint256 totalInitialBorrowPrice = 0;
        for (uint256 i = 0; i < borrowedTokens.length; i++) totalInitialBorrowPrice = totalInitialBorrowPrice.add(initialBorrowPrice(borrowedTokens[i], account_));
        return (collateralPrice.mul(maxLeverage) >= totalInitialBorrowPrice);
    }
}
