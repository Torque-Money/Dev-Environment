//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";

import {MockStrategy} from "@contracts/mocks/MockStrategy.sol";

contract VaultTest is DSTest {
    MockStrategy strategy;

    function setUp() public {
        strategy = new MockStrategy();
        strategy.initialize(token, initialAPY);
    }
}
