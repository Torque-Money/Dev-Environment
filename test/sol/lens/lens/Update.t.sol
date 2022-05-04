//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseLens} from "./BaseLens.sol";

contract UpdateTest is BaseLens {
    // Test that the lens can update the strategies
    function testUpdate() public {
        // **** We will need to deposit some funds, have the strategy move the funds over a few times, and then run a withdraw and check it is roughly the same for the vault
        // **** Also need to make sure that the funds deposited go into the correct vault (we will do this using approx eq)
    }
}
