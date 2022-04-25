//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "./ICheatCodes.sol";

abstract contract Impersonate {
    modifier impersonate(address impersonator) {
        ICheatCodes cheats = _getCheats();

        cheats.startPrank(impersonator);
        _;
        cheats.stopPrank();
    }

    function _getCheats() internal view virtual returns (ICheatCodes _cheats);
}
