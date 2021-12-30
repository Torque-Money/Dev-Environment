//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../LPool/LPool.sol";

abstract contract SwapCore is Ownable {
    LPool public pool;

    constructor(LPool pool_) {
        pool = pool_;
    }

    // Set the pool
    function setPool(LPool pool_) external onlyOwner {
        pool = pool_;
    }
}