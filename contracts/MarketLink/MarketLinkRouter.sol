//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarketLinkCore.sol";
import "../lib/UniswapV2Router02.sol";

abstract contract MarketLinkRouter is MarketLinkCore {
    using SafeMath for uint256;

    UniswapV2Router02[] private _routers;
    mapping(UniswapV2Router02 => bool) private _addedRouters;

    // Add a new router
    function addRouter(UniswapV2Router02 _router) external onlyOwner {
        require(!_addedRouters[_router], "Router has already been added");
        _routers.push(_router);
        _addedRouters[_router] = true;
    }

    // Get a pseudo-random router
    function router() external view returns (UniswapV2Router02) {
        uint256 index = block.timestamp.mod(_routers.length);
        return _routers[index];
    }
}