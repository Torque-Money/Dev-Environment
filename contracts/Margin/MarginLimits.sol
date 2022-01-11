//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginLevel.sol";
import "./MarginCore.sol";

abstract contract MarginLimits is MarginCore {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

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
}
