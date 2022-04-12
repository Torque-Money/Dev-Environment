//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "ds-test/test.sol";

import {TorqueTAU} from "@contracts/TorqueTAU/TorqueTAU.sol";

contract TorqueTAUTest is DSTest {
    TorqueTAU tau;

    function setUp() public {
        tau = new TorqueTAU();
    }

    function testExample() public {
        assertTrue(true);
    }
}
