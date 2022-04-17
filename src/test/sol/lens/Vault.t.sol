//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MockStrategy} from "../../mocks/MockStrategy.sol";
import {TorqueVaultV1} from "@contracts/lens/vault/TorqueVaultV1.sol";

import {Config} from "../helpers/Config.sol";

contract VaultTest is DSTest {
    IERC20[] private token;

    TorqueVaultV1 private vault;
    MockStrategy private strategy;

    function setUp() external {
        token = Config.getTokens();

        vault = new TorqueVaultV1();
        // vault.initialize(token, );

        strategy = new MockStrategy();
        strategy.initialize(token, Config.getInitialAPY());

        Config.fundCaller();
    }

    function testFunded() external {
        assertGt(token[0].balanceOf(address(this)), 0);
        assertGt(token[1].balanceOf(address(this)), 0);
    }
}
