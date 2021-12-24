//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./LPool.sol";
import "./Oracle.sol";
import "./lib/Margin/MarginBorrow.sol";

contract Margin is MarginBorrow {
    constructor(
        Oracle oracle_,
        LPool pool_,
        uint256 minMarginThreshold_,
        uint256 minBorrowLength_,
        uint256 maxInterestPercent_ 
    )
    MarginCore(oracle_, pool_)
    MarginLevel(minMarginThreshold_)
    MarginBorrowHelper(minBorrowLength_)
    MarginInterest(maxInterestPercent_)
    {}
}