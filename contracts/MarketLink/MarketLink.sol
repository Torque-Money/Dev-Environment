//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../LPool/LPool.sol";
import "./MarketLinkPrice.sol";
import "./MarketLinkSwap.sol";

contract MarketLink is MarketLinkPrice, MarketLinkSwap {
    constructor(LPool pool_)
        MarketLinkCore(pool_)
    {}
}