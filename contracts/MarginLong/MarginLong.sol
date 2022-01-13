//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./MarginLongBorrow.sol";
import "./MarginLongRepay.sol";
import "./MarginLongLiquidate.sol";
import "../Oracle/IOracle.sol";

contract MarginLong is MarginLongBorrow, MarginLongRepay, MarginLongLiquidateCore {
    constructor(
        LPool pool_,
        IOracle oracle_,
        uint256 minMarginLevelPercent_,
        uint256 minCollateralPrice_,
        uint256 maxLeverage_,
        uint256 repayTaxPercent_,
        uint256 liquidationFeePercent_
    )
        MarginCore(pool_, oracle_)
        MarginLevel(minMarginLevelPercent_, 100)
        MarginLimits(minCollateralPrice_, maxLeverage_)
        MarginLongRepayCore(repayTaxPercent_, 100)
        MarginLongLiquidateCore(liquidationFeePercent_, 100)
    {}
}
