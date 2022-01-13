//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./MarginLongBorrow.sol";
import "./MarginLongRepay.sol";
import "./MarginLongLiquidate.sol";
import "../Oracle/IOracle.sol";

contract MarginLong is MarginLongBorrow, MarginLongRepay, MarginLongLiquidate {
    constructor(
        LPool pool_,
        IOracle oracle_,
        uint256 minMarginLevelNumerator_,
        uint256 minMarginLevelDenominator_,
        uint256 minCollateralPrice_,
        uint256 maxLeverage_,
        uint256 repayTaxNumerator_,
        uint256 repayTaxDenominator_,
        uint256 liquidationFeePercentNumerator_,
        uint256 liquidationFeePercentDenominator_
    )
        MarginCore(pool_, oracle_)
        MarginLevel(minMarginLevelNumerator_, minMarginLevelDenominator_)
        MarginLimits(minCollateralPrice_, maxLeverage_)
        MarginLongRepayCore(repayTaxNumerator_, repayTaxDenominator_)
        MarginLongLiquidateCore(liquidationFeePercentNumerator_, liquidationFeePercentDenominator_)
    {}
}
