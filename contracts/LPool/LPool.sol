//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./LPoolManipulation.sol";

contract LPool is LPoolManipulation {
    constructor(uint256 taxPercent_)
        LPoolTax(taxPercent_)
    {}
}