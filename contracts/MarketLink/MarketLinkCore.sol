//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../LPool/LPool.sol";

abstract contract MarketLinkCore is Ownable {
    LPool public pool;

    constructor(LPool pool_) {
        pool = pool_;
    }

    // Set the liquidity pool
    function setPool(LPool _pool) external onlyOwner {
        pool = _pool;
    }
}