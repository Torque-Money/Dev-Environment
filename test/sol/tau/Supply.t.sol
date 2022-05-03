//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseTAU} from "./BaseTAU.sol";

contract Authorize is BaseTAU {
    // Test the initial supply
    function testInitialSupply() public {
        assertEq(tau.totalSupply(), initialSupply);
        assertEq(tau.balanceOf(address(this)), initialSupply);
    }

    // Test minting and burning
    function testMintBurn() public {
        // **** I need to check the amounts work as I expect
        tau.mint(address(this), mintAmount);
        tau.burn(address(this), mintAmount);
    }
}
