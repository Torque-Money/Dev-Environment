//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseTAU} from "./BaseTAU.sol";
import {BaseImpersonate} from "../bases/BaseImpersonate.sol";

contract Authorize is BaseTAU, BaseImpersonate {
    // Fail to mint tokens
    function testFailMint() public impersonate(vm, _empty) {
        _tau.mint(address(this), _mintAmount);
    }

    // Fail to burn tokens
    function testFailBurn() public impersonate(vm, _empty) {
        _tau.burn(address(this), _mintAmount);
    }
}
