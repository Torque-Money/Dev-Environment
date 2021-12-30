//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../LPool/LPool.sol";
import "./SwapTokens.sol";

contract Swap is SwapTokens {
    constructor(LPool pool_)
        SwapCore(pool_)
    {}
}