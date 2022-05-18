//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseRegistry} from "./BaseRegistry.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

contract AuthorizeTest is BaseRegistry, BaseImpersonate {
    // Check unauthorized accounts cant add to the registry
    function testFailAdd() public impersonate(vm, _empty) {
        _registry.add(address(0));
    }

    // Check unauthorized accounts cant remove from the registry
    function testFailRemove() public impersonate(vm, _empty) {
        _registry.remove(address(0));
    }
}
