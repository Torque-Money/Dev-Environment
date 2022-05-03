//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {Base} from "../../helpers/Base.sol";

import {MockRegistry} from "../../../mocks/MockRegistry.sol";

contract RegistryBase is Base {
    MockRegistry private registry;

    function setUp() public virtual override {
        super.setUp();

        registry = new MockRegistry();
    }

    function _getRegistry() internal view returns (MockRegistry _registry) {
        return registry;
    }
}
