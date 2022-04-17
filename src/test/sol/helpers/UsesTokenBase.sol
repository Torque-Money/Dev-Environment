//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Config} from "./Config.sol";
import {ICheatCodes} from "./ICheatCodes.sol";

contract UsesTokenBase {
    using SafeERC20 for IERC20;

    modifier useFunds() {
        _fundCaller();
        _;
        _defundCaller();
    }

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

    // Withdraw all funds from the contract back into the whales
    function _defundCaller() internal {
        IERC20[] memory token = Config.getToken();
        address[] memory tokenWhale = Config.getTokenWhale();

        for (uint256 i = 0; i < token.length; i++) token[i].safeTransfer(tokenWhale[i], token[i].balanceOf(address(this)));
    }

    // Approves funds for use with the given contracts
    function _approveAll(address[] memory spender) internal {
        IERC20[] memory token = Config.getToken();

        uint256 MAX_INT = 2**256 - 1;

        for (uint256 i = 0; i < token.length; i++) for (uint256 j = 0; j < spender.length; j++) token[i].approve(spender[j], MAX_INT);
    }
}
