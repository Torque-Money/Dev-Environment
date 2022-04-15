//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "ds-test/test.sol";

import {TorqueTAU} from "@contracts/tau/TorqueTAU.sol";

contract TorqueTAUTest is DSTest {
    TorqueTAU tau;

    uint256 constant INITIAL_SUPPLY = 10000 * 1e18;

    uint256 constant MINT_AMOUNT = 10 * 1e18;

    function setUp() public {
        tau = new TorqueTAU();
        tau.initialize(INITIAL_SUPPLY);
    }

    // Check the initial supply minted
    function testInitialSupply() public {
        assertEq(tau.totalSupply(), INITIAL_SUPPLY, "Total supply does not match initially supply minted");
        assertEq(tau.balanceOf(address(this)), INITIAL_SUPPLY, "Balance of minter does not match supply minted");
    }

    // Fail to mint and burn tokens
    function testFailMintBurn() public {
        tau.mint(address(this), MINT_AMOUNT);
        tau.burn(address(this), MINT_AMOUNT);
    }

    // Mint and burn tokens
    function testMintBurn() public {
        tau.grantRole(tau.TOKEN_MINTER_ROLE(), address(this));
        tau.grantRole(tau.TOKEN_BURNER_ROLE(), address(this));

        tau.mint(address(this), MINT_AMOUNT);
        tau.burn(address(this), MINT_AMOUNT);

        tau.revokeRole(tau.TOKEN_BURNER_ROLE(), address(this));
        tau.revokeRole(tau.TOKEN_MINTER_ROLE(), address(this));
    }
}
