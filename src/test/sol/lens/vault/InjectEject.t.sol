//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {VaultBase} from "./VaultBase.sol";

contract InjectEjectTest is VaultBase {
    function testDepositAllIntoStrategy() public useFunds {
        // **** We want to move the funds back and fourth using the withdraw
    }
}
