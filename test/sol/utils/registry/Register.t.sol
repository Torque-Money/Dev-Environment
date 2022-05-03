//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {RegistryBase} from "./RegistryBase.sol";
import {Impersonate} from "../../helpers/Impersonate.sol";

import {MockRegistry} from "../../../mocks/MockRegistry.sol";

contract Register is RegistryBase, Impersonate {
    MockRegistry private registry;
    address private empty;

    function setUp() public override {
        super.setUp();

        registry = _getRegistry();
        empty = _getEmpty();
    }

    // Check that an approved account will be able to use an admin function
    function testRegister() public {
        registry.add(empty);

        assertTrue(registry.isEntry(empty));
        assertEq(registry.entryCount(), 1);
        assertEq(registry.entryByIndex(0), empty);

        registry.remove(empty);

        assertTrue(!registry.isEntry(empty));
        assertEq(registry.entryCount(), 0);
    }

    // Check that a non registered entry cant be removed
    function testFailRemoveInvalid() public {
        registry.remove(empty);
    }

    // Check that a non registered entry cant be removed
    function testFailInvalidIndex() public view {
        registry.entryByIndex(0);
    }

    // Check that a duplicate entry cannot be made
    function testFailDuplicateEntry() public {
        registry.add(empty);
        registry.add(empty);
    }

    function _getCheats() internal view virtual override(RegistryBase, Impersonate) returns (ICheatCodes _cheats) {
        return super._getCheats();
    }
}