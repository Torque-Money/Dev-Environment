//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {ICheatCodes} from "./ICheatCodes.sol";

import {Config} from "./Config.sol";
import {Empty} from "./Empty.sol";
import {AssertUtils} from "./AssertUtils.sol";

contract Base is DSTest {
    ICheatCodes private cheats;
    address private empty;

    uint256 private fosPercent;
    uint256 private fosDenominator;

    function setUp() public virtual {
        empty = address(new Empty());

        cheats = Config.getCheatCodes();

        fosPercent = Config.getFosPercent();
        fosDenominator = Config.getFosDenominator();
    }

    function _getEmpty() internal view virtual returns (address _empty) {
        return empty;
    }

    function _getCheats() internal view virtual returns (ICheatCodes _cheats) {
        return cheats;
    }

    function _assertApproxEq(uint256 a, uint256 b) internal view {
        AssertUtils.assertApproxEq(a, b, fosPercent, fosDenominator);
    }
}
