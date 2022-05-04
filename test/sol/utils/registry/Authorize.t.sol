//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseRegistry} from "./BaseRegistry.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

contract AuthorizeTest is BaseRegistry, BaseImpersonate {
    // Check that an approved account will be able to use the admin add function
    function testAuthorizedAdd() public {
        _registry.add(_empty);
    }

    // Check that an approved account will be able to use the admin remove function
    function testAuthorizedRemove() public {
        _registry.add(_empty);
        _registry.remove(_empty);
    }

    // Check that a non approved account will not be able to use the admin add function
    function testFailUnauthorizedAdd() public impersonate(vm, _empty) {
        _registry.add(address(0));
    }

    // Check that a non approved account will not be able to use the admin remove function
    function testFailUnauthorizedRemove() public impersonate(vm, _empty) {
        _registry.remove(address(0));
    }
}
