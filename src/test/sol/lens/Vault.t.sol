//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MockStrategy} from "@contracts/mocks/MockStrategy.sol";

import {Config} from "../Config.sol";

contract VaultTest is DSTest {
    MockStrategy private strategy;
    IERC20[] private token;

    function setUp() public {
        token = Config.getTokens();

        strategy = new MockStrategy();
        strategy.initialize(token, Config.getInitialAPY());

        Config.fundCaller();

        emit log_uint(token[0].balanceOf(address(this)));
    }
}
