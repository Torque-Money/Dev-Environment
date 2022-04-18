//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "./ICheatCodes.sol";

contract Impersonate {
    modifier impersonate(ICheatCodes cheats, address impersonator) {
        cheats.startPrank(impersonator);
        _;
        cheats.stopPrank();
    }
}
