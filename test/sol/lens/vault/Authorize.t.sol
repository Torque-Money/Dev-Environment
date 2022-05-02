//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {VaultBase} from "./VaultBase.sol";
import {Impersonate} from "../../helpers/Impersonate.sol";

import {Config} from "../../helpers/Config.sol";
import {TorqueVaultV1} from "../../../../src/lens/vault/TorqueVaultV1.sol";

contract AuthorizeTest is VaultBase, Impersonate {
    TorqueVaultV1 private vault;
    address private empty;
    ICheatCodes private cheats;

    function setUp() public override {
        super.setUp();

        vault = _getVault();
        empty = _getEmpty();
        cheats = _getCheats();
    }

    // Fail to deposit moving funds into the strategy due to lack of authorization.
    function testFailInjectFunds() public impersonate(empty) {
        vault.depositIntoStrategy(Config.getTokenAmount());
    }

    // Fail to deposit moving all funds into the strategy due to lack of authorization.
    function testFailInjectAllFunds() public impersonate(empty) {
        vault.depositAllIntoStrategy();
    }

    // Fail to deposit moving funds from the strategy due to lack of authorization.
    function testFailEjectFunds() public impersonate(empty) {
        vault.withdrawFromStrategy(Config.getTokenAmount());
    }

    // Fail to deposit moving all funds from the strategy due to lack of authorization.
    function testFailEjectAllFunds() public impersonate(empty) {
        vault.withdrawAllFromStrategy();
    }

    function _getCheats() internal view override(VaultBase, Impersonate) returns (ICheatCodes _cheats) {
        return super._getCheats();
    }
}
