//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../Oracle/Oracle.sol";
import "../FlashSwap/FlashSwap.sol";
import "../LPool/LPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsolatedMarginBorrow.sol";
import "./IsolatedMarginRepay.sol";
import "./IsolatedMarginLiquidate.sol";

contract IsolatedMargin is IsolatedMarginBorrow, IsolatedMarginRepay, IsolatedMarginLiquidate {
    constructor(
        LPool pool_, Oracle oracle_, FlashSwap flashSwap_, uint256 swapTolerance_,
        uint256 minMarginLevel_,
        uint256 minCollateral_,
        uint256 liquidationFeePercent_
    )
        MarginCore(pool_, oracle_, flashSwap_, swapTolerance_)
        IsolatedMarginLevel(minMarginLevel_)
        IsolatedMarginBorrow(minCollateral_)
        IsolatedMarginLiquidate(liquidationFeePercent_)
    {}
}