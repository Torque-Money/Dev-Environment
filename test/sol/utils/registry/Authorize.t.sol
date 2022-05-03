//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseRegistry} from "./BaseRegistry.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

import {MockRegistry} from "../../../mocks/MockRegistry.sol";

contract Authorize is RegistryBase, Impersonate {
    MockRegistry private registry;
    address private empty;

    function setUp() public override {
        super.setUp();

        registry = _getRegistry();
        empty = _getEmpty();
    }

    // Check that an approved account will be able to use an admin function
    function testAuthorized() public {
        registry.add(empty);
    }

    // Check that a non approved account will not be able to use an admin function
    function testFailUnauthorized() public impersonate(vm, _empty) {
        registry.add(address(0));
    }

    function _getCheats() internal view virtual override(RegistryBase, Impersonate) returns (ICheatCodes _cheats) {
        return super._getCheats();
    }
}
