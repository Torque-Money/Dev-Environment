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
        ICheatCodes cheats = Config.getCheatCodes();

        cheats.startPrank(whales[0]);
        token[0].transfer(address(this), token[0].balanceOf(whales[0]));
        cheats.stopPrank();

        cheats.startPrank(whales[1]);
        token[1].transfer(address(this), token[1].balanceOf(whales[1]));
        cheats.stopPrank();
    }

    function getToken() public pure returns (IERC20[] memory token) {
        return Config.getToken();
    }

    function getTokenAmount() public pure returns (uint256[] memory amount) {}
}
