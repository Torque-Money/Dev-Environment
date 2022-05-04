//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseLens} from "./BaseLens.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

contract AuthorizeTest is BaseLens, BaseImpersonate {
    // Should set the vault
    function testSetVault() public {
        _lens.setVault(_vault);
    }

    // Should fail to set the vault due to lack of authorization
    function testFailUnauthorizedSetVault() public impersonate(vm, _empty) {
        _lens.setVault(_vault);
    }
}
