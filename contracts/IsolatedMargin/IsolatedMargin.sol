//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Oracle/Oracle.sol";
import "../FlashSwap/FlashSwap.sol";
import "../LPool/LPool.sol";
import "./IsolatedMarginBorrow.sol";
import "./IsolatedMarginRepay.sol";
import "./IsolatedMarginLiquidate.sol";

contract IsolatedMargin is IsolatedMarginBorrow, IsolatedMarginRepay, IsolatedMarginLiquidate {
    constructor(
        LPool pool_, Oracle oracle_, FlashSwap flashSwap_, uint256 swapToleranceNumerator_, uint256 swapToleranceDenominator_,
        uint256 minMarginLevelNumerator_, uint256 minMarginLevelDenominator_,
        uint256 minCollateral_,
        uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_
    )
        MarginCore(pool_, oracle_, flashSwap_, swapToleranceNumerator_, swapToleranceDenominator_)
        IsolatedMarginLevel(minMarginLevelNumerator_, minMarginLevelDenominator_)
        IsolatedMarginBorrow(minCollateral_)
        IsolatedMarginLiquidate(liquidationFeePercentNumerator_, liquidationFeePercentDenominator_)
    {}
}