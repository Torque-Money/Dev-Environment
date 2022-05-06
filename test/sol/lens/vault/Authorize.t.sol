//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseVault} from "./BaseVault.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

contract AuthorizeTest is BaseVault, BaseImpersonate {
    // Fail to set the strategy due to lack of authorization.
    function testSetStrategy() public impersonate(vm, _empty) {
        _vault.setStrategy(_vault.getStrategy());
    }
}
