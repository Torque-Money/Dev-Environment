//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {TimelockControllerUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";

contract Timelock is Initializable, TimelockControllerUpgradeable {
    function initialize(
        uint256 minDelay_,
        address[] memory proposers_,
        address[] memory executors_
    ) external initializer {
        __TimelockController_init(minDelay_, proposers_, executors_);
    }
}
