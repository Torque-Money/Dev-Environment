//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {UsesTokenBase} from "../helpers/UsesTokenBase.sol";

import {Config} from "../helpers/Config.sol";
import {Empty} from "../helpers/Empty.sol";
import {MockStrategy} from "../../mocks/MockStrategy.sol";
import {TorqueVaultV1} from "@contracts/lens/vault/TorqueVaultV1.sol";

contract VaultTest is DSTest, UsesTokenBase {
    Empty private empty;
    TorqueVaultV1 private vault;
    MockStrategy private strategy;

    function setUp() public override {
        super.setUp();

        empty = new Empty();

        vault = new TorqueVaultV1();
        vault.initialize(Config.getToken(), address(empty), 1, 1000);

        strategy = new MockStrategy();
        strategy.initialize(Config.getToken(), Config.getInitialAPY());
    }

    function testDepositRedeem() public {}

    function testDepositRedeemZero() public {}

    function testDepositRedeemNormalWithFunds() public {}

    function testFailDepositAllIntoStrategy() public {}

    function testDepositAllIntoStrategy() public {}
}
