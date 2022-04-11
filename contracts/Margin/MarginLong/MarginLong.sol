//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {MarginLongBorrow} from "./MarginLongBorrow.sol";
import {MarginLongRepay} from "./MarginLongRepay.sol";
import {MarginLongLiquidate} from "./MarginLongLiquidate.sol";

contract MarginLong is Initializable, MarginLongBorrow, MarginLongRepay, MarginLongLiquidate {
    function initialize(
        address pool_,
        address oracle_,
        uint256 minCollateralPrice_,
        uint256 maxLeverageNumerator_,
        uint256 maxLeverageDenominator_,
        uint256 liquidationFeePercentNumerator_,
        uint256 liquidationFeePercentDenominator_
    ) external initializer {
        initializeMarginCore(pool_, oracle_);
        initializeMarginLimits(minCollateralPrice_);
        initializeMarginLevel(maxLeverageNumerator_, maxLeverageDenominator_);
        initializeMarginLongLiquidateCore(liquidationFeePercentNumerator_, liquidationFeePercentDenominator_);
    }
}
