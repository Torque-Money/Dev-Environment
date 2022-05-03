//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {RegistryUpgradeable} from "../../src/utils/RegistryUpgradeable.sol";

contract MockRegistry is Initializable, RegistryUpgradeable {
    constructor() {
        _initialize();
    }

    function _initialize() internal initializer {
        __Registry_init();
    }
}
