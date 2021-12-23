//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./lib/LPool/LPoolAccount.sol";
import "./lib/LPool/LPoolAdmin.sol";
import "./lib/LPool/LPoolApproved.sol"; // Done
import "./lib/LPool/LPoolCore.sol"; // Done
import "./lib/LPool/LPoolLiquidity.sol"; // Done
import "./lib/LPool/LPoolPeriod.sol"; // Done
import "./lib/LPool/LPoolTax.sol"; // Done

// **** Problem occurs with account and with admin - potentially add seperate interfaces into them or something ?
contract LPool is LPoolCore, LPoolPeriod, LPoolApproved, LPoolTax, LPoolLiquidity {
    constructor(uint256 periodLength_, uint256 cooldownLength_, uint256 taxPercent_)
    LPoolPeriod(periodLength_, cooldownLength_)
    LPoolTax(taxPercent_)
    {}
}