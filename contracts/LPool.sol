//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./lib/LPool/LPoolAccount.sol";
import "./lib/LPool/LPoolAdmin.sol";

contract LPool is LPoolAccount, LPoolAdmin {
    constructor(uint256 periodLength_, uint256 cooldownLength_, uint256 taxPercent_)
    LPoolPeriod(periodLength_, cooldownLength_)
    LPoolTax(taxPercent_)
    {}
}