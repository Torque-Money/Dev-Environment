//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/TimelockController.sol";
import "./TimelockTax.sol";

contract Timelock is TimelockController, TimelockTax {
    constructor(
        uint256 minDelay_,
        address[] memory proposers_,
        address[] memory executors_,
        uint256 taxPercentageNumerator_,
        uint256 taxPercentageDenominator_,
        uint256 taxCooldown_
    ) TimelockController(minDelay_, proposers_, executors_) TimelockTax(taxPercentageNumerator_, taxPercentageDenominator_, taxCooldown_) {}
}
