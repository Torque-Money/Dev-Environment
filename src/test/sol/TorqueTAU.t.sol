//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {CheatCodes} from "./CheatCodes.t.sol";

import {TorqueTAU} from "contracts/TorqueTAU/TorqueTAU.sol";

contract TorqueTAUTest is DSTest {
    CheatCodes cheats;
    TorqueTAU tau;

    uint256 constant INITIAL_SUPPLY = 10000 * 1e18;

    function setUp() public {
        cheats = CheatCodes(HEVM_ADDRESS);
        tau = new TorqueTAU();
        tau.initialize(INITIAL_SUPPLY);
    }

    // Check the initial supply minted
    function testInitialSupply() public {
        assertEq(tau.totalSupply(), INITIAL_SUPPLY, "Total supply does not match initially supply minted");
        assertEq(tau.balanceOf(msg.sender), INITIAL_SUPPLY, "Balance of minter does not match supply minted");
    }

    // Mint with 
    function testMintNoRole() public {
    }

    // Mint with roles
    function testBurnNoRole() public {}
}
