//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./MarginLongBorrow.sol";
import "./MarginLongRepay.sol";
import "./MarginLongLiquidate.sol";
import "../Oracle/IOracle.sol";

contract MarginLong is Initializable, MarginLongBorrow, MarginLongRepay, MarginLongLiquidate {
    function initialize(
        LPool pool_,
        IOracle oracle_,
        uint256 minMarginLevelNumerator_,
        uint256 minMarginLevelDenominator_,
        uint256 minCollateralPrice_,
        uint256 maxLeverage_,
        uint256 liquidationFeePercentNumerator_,
        uint256 liquidationFeePercentDenominator_
    ) external initializer {
        initializeMarginCore(pool_, oracle_);
        initializeMarginLevel(minMarginLevelNumerator_, minMarginLevelDenominator_);
        initializeMarginLimits(minCollateralPrice_, maxLeverage_);
        initializeMarginLongLiquidateCore(liquidationFeePercentNumerator_, liquidationFeePercentDenominator_);
    }
}
