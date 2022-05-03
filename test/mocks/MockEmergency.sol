//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {EmergencyUpgradeable} from "../../src/utils/EmergencyUpgradeable.sol";

contract MockEmergency is Initializable, EmergencyUpgradeable {
    constructor() {
        _initialize();
    }

    function _initialize() internal initializer {
        __Emergency_init();
    }
}
