//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../LPool/LPool.sol";
import "./FlashSwapTokens.sol";

contract FlashSwap is FlashSwapTokens {
    constructor(LPool pool_)
        SwapCore(pool_)
    {}
}