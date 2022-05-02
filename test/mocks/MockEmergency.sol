//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {EmergencyUpgradeable} from "../../src/utils/EmergencyUpgradeable.sol";

contract MockEmergency is EmergencyUpgradeable {
    constructor() {
        __Emergency_init();
    }
}
