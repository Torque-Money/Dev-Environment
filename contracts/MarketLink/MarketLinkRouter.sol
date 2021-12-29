//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../lib/UniswapV2Router02.sol";
import "./MarketLinkCore.sol";

abstract contract MarketLinkRouter is MarketLinkCore {
    UniswapV2Router02 public router;

    // Set the router
    function setRouter(UniswapV2Router02 router_) external onlyOwner {
        router = router_;
    }
}