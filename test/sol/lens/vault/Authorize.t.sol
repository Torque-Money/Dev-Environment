//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseVault} from "./BaseVault.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

import {Config} from "../../helpers/Config.sol";

contract AuthorizeTest is BaseVault, BaseImpersonate {
    // Fail to deposit moving funds into the strategy due to lack of authorization.
    function testFailInjectFunds() public impersonate(empty) {
        _vault.depositIntoStrategy(Config.getTokenAmount());
    }

    // Fail to deposit moving all funds into the strategy due to lack of authorization.
    function testFailInjectAllFunds() public impersonate(empty) {
        _vault.depositAllIntoStrategy();
    }

    // Fail to deposit moving funds from the strategy due to lack of authorization.
    function testFailEjectFunds() public impersonate(empty) {
        _vault.withdrawFromStrategy(Config.getTokenAmount());
    }

    // Fail to deposit moving all funds from the strategy due to lack of authorization.
    function testFailEjectAllFunds() public impersonate(empty) {
        _vault.withdrawAllFromStrategy();
    }
}
