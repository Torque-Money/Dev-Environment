//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {VaultBase} from "./VaultBase.sol";

import {Config} from "../../helpers/Config.sol";
import {Empty} from "../../helpers/Empty.sol";
import {MockStrategy} from "../../../mocks/MockStrategy.sol";
import {TorqueVaultV1} from "@contracts/lens/vault/TorqueVaultV1.sol";

contract AuthorizeTest is VaultBase {
    TorqueVaultV1 private vault;
    Empty private empty;
    ICheatCodes private cheats;

    function setUp() public override {
        super.setUp();

        vault = _getVault();
        empty = _getEmpty();
        cheats = Config.getCheatCodes();
    }

    modifier impersonate() {
        cheats.startPrank(address(empty));
        _;
        cheats.stopPrank();
    }

    function testFailInjectFunds() public impersonate {
        vault.depositIntoStrategy(Config.getTokenAmount());
    }

    function testFailInjectAllFunds() public impersonate {
        vault.depositAllIntoStrategy();
    }

    function testFailEjectFunds() public impersonate {
        vault.withdrawFromStrategy(Config.getTokenAmount());
    }

    function testFailEjectAllFunds() public impersonate {
        vault.withdrawAllFromStrategy();
    }
}
