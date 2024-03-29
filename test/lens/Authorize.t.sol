//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseLens} from "./BaseLens.sol";
import {BaseImpersonate} from "../bases/BaseImpersonate.sol";

contract AuthorizeTest is BaseLens, BaseImpersonate {
    // Should update the strategy due to lack of authorization
    function testFailUpdate() public impersonate(vm, _empty) {
        _lens.update(_strategy[0]);
    }
}
