//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseRegistry} from "./BaseRegistry.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

contract Authorize is BaseRegistry, BaseImpersonate {
    // Check that an approved account will be able to use an admin function
    function testAuthorized() public {
        _registry.add(_empty);
    }

    // Check that a non approved account will not be able to use an admin function
    function testFailUnauthorized() public impersonate(vm, _empty) {
        _registry.add(address(0));
    }
}
