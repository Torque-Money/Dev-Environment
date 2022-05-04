//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseRegistry} from "./BaseRegistry.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

contract RegisterTest is BaseRegistry, BaseImpersonate {
    // Check that an approved account will be able to use an admin function
    function testRegister() public {
        _registry.add(_empty);

        assertTrue(_registry.isEntry(_empty));
        assertEq(_registry.entryCount(), 1);
        assertEq(_registry.entryByIndex(0), _empty);

        _registry.remove(_empty);

        assertTrue(!_registry.isEntry(_empty));
        assertEq(_registry.entryCount(), 0);
    }

    // Check that a non registered entry cant be removed
    function testFailRemoveInvalid() public {
        _registry.remove(_empty);
    }

    // Check that a non registered entry cant be removed
    function testFailInvalidIndex() public view {
        _registry.entryByIndex(0);
    }

    // Check that a duplicate entry cannot be made
    function testFailDuplicateEntry() public {
        _registry.add(_empty);
        _registry.add(_empty);
    }
}
