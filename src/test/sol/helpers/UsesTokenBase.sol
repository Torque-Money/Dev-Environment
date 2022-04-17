//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Config} from "./Config.sol";
import {ICheatCodes} from "./ICheatCodes.sol";

contract UsesTokenBase is DSTest {
    function setUp() public {
        _fundCaller();
    }

    function _fundCaller() internal {
        IERC20[] memory token = Config.getToken();
        address[] memory tokenWhale = Config.getTokenWhale();

        ICheatCodes cheats = Config.getCheatCodes();

        cheats.startPrank(tokenWhale[0]);
        token[0].transfer(address(this), token[0].balanceOf(tokenWhale[0]));
        cheats.stopPrank();

        cheats.startPrank(tokenWhale[1]);
        token[1].transfer(address(this), token[1].balanceOf(tokenWhale[1]));
        cheats.stopPrank();
    }
}
