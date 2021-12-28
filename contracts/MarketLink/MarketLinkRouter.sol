//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./MarketLinkCore.sol";
import "../lib/UniswapV2Router02.sol";

abstract contract MarketLinkRouter is MarketLinkCore {
    UniswapV2Router02 public router;

    // Set the router
    function setRouter(UniswapV2Router02 _router) external onlyOwner {
        router = _router;
    }
}