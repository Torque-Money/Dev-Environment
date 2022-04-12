//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {CheatCodes} from "./CheatCodes.t.sol";

import {TorqueTAU} from "contracts/TorqueTAU/TorqueTAU.sol";

contract TorqueTAUTest is DSTest {
    CheatCodes cheats;
    TorqueTAU tau;

    function setUp() public {
        cheats = CheatCodes(HEVM_ADDRESS);
        tau = new TorqueTAU();
    }

    function testMint() public {
        cheats.expectRevert();
    }
}
