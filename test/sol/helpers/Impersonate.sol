//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Vm} from "forge-std/Vm.sol";

abstract contract Impersonate {
    modifier impersonate(Vm vm, address impersonator) {
        vm.startPrank(impersonator);
        _;
        vm.stopPrank();
    }
}
