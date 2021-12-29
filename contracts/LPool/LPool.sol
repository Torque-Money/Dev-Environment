//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./LPoolStake.sol";
import "./LPoolInterest.sol";

contract LPool is LPoolStake, LPoolInterest {
    constructor(uint256 taxPercent_, uint256 blocksPerCompound_)
        LPoolTax(taxPercent_)
        LPoolInterest(blocksPerCompound_)
    {}
}