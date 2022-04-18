//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {ICheatCodes} from "./ICheatCodes.sol";

import {Config} from "./Config.sol";
import {Empty} from "./Empty.sol";

contract StrategyBase is DSTest {
    ICheatCodes private cheats;
    address private empty;

    function setUp() public virtual {
        empty = address(new Empty());

        cheats = Config.getCheatCodes();
    }

    function _getEmpty() internal view returns (address _empty) {
        return empty;
    }

    function _getCheats() internal view returns (ICheatCodes _cheats) {
        return cheats;
    }
}
