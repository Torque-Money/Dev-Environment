//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginAccount.sol";

abstract contract MarginBorrow is MarginAccount {
    using SafeMath for uint256;

    uint256 public minCollateralPrice;

    constructor(uint256 minCollateralPrice_) {
        minCollateralPrice = minCollateralPrice_;
    }

    // Set the minimum collateral price
    function setMinCollateralPrice(uint256 minCollateralPrice_) external onlyOwner returns (uint256) {
        minCollateralPrice = minCollateralPrice_;
    }
}