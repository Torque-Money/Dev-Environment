//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {CheatCodes} from "./CheatCodes.t.sol";

import {TorqueTAU} from "contracts/TorqueTAU/TorqueTAU.sol";

contract TorqueTAUTest is DSTest {
    CheatCodes cheats;
    TorqueTAU tau;

    uint256 constant INITIAL_SUPPLY = 10000 * 1e18;

    uint256 constant MINT_AMOUNT = 10 * 1e18;
    uint256 constant BURN_AMOUNT = 10 * 1e18;

    function setUp() public {
        cheats = CheatCodes(HEVM_ADDRESS);
        tau = new TorqueTAU();
        tau.initialize(INITIAL_SUPPLY);
    }

    // Check the initial supply minted
    function testInitialSupply() public {
        assertEq(tau.totalSupply(), INITIAL_SUPPLY, "Total supply does not match initially supply minted");
        assertEq(tau.balanceOf(address(this)), INITIAL_SUPPLY, "Balance of minter does not match supply minted");
    }

    // Fail to mint tokens
    function testFailMint() public {
        tau.mint(address(this), MINT_AMOUNT);
    }

    // Fail to burn tokens
    function testFailBurn() public {
        tau.burn(address(this), BURN_AMOUNT);
    }

    // Mint tokens
    function testMint() public {
        tau.mint(address(this), MINT_AMOUNT);
    }

    // Burn tokens
    function testBurn() public {
        tau.burn(address(this), BURN_AMOUNT);
    }
}
