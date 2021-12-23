//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract Timelock is TimelockController {
    address public taxAccount;
    uint256 public immutable taxPercentage;

    uint256 public immutable taxCooldown;
    uint256 public lastTax;

    constructor(
        uint256 minDelay_,
        address[] memory proposers_,
        address[] memory executors_,
        uint256 taxPercentage_,
        uint256 taxCooldown_
    ) TimelockController(minDelay_, proposers_, executors_) {
        taxAccount = _msgSender();
        taxPercentage = taxPercentage_;
        taxCooldown = taxCooldown_;
    }
}