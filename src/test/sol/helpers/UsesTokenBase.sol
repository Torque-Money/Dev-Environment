//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Config} from "./Config.sol";
import {ICheatCodes} from "./ICheatCodes.sol";

contract UsesTokenBase {
    using SafeERC20 for IERC20;

    // Fund a contract with the required tokens
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

    // Approves funds for use with the given contracts
    function _approveAll(address[] memory spender) internal {
        IERC20[] memory token = Config.getToken();
        require(spender.length == token.length, "UsesTokenBase: Spender list length must match token length");

        uint256 MAX = 2**256 - 1;

        for (uint256 i = 0; i < token.length; i++) token[0].safeIncreaseAllowance(spender[0], MAX);
    }
}
