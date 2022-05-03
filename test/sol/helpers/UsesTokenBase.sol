//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ICheatCodes} from "./ICheatCodes.sol";

import {Config} from "./Config.sol";

abstract contract UsesTokenBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    modifier useFunds() {
        _fundCaller();
        _;
        _defundCaller();
    }

    // Fund a contract with the required tokens
    function _fundCaller() internal {
        IERC20Upgradeable[] memory token = Config.getToken();
        address[] memory tokenWhale = Config.getTokenWhale();

        ICheatCodes cheats = _getCheats();

        for (uint256 i = 0; i < token.length; i++) {
            cheats.startPrank(tokenWhale[i]);
            token[i].safeTransfer(address(this), token[i].balanceOf(tokenWhale[i]));
            cheats.stopPrank();
        }
    }

    // Withdraw all funds from the contract back into the whales
    function _defundCaller() internal {
        IERC20Upgradeable[] memory token = Config.getToken();
        address[] memory tokenWhale = Config.getTokenWhale();

        for (uint256 i = 0; i < token.length; i++) token[i].safeTransfer(tokenWhale[i], token[i].balanceOf(address(this)));
    }

    // Approves funds for use with the given contracts
    function _approveAll(address[] memory spender) internal {
        IERC20Upgradeable[] memory token = Config.getToken();

        uint256 MAX_INT = 2**256 - 1;

        for (uint256 i = 0; i < token.length; i++) for (uint256 j = 0; j < spender.length; j++) token[i].approve(spender[j], MAX_INT);
    }

    function _getCheats() internal view virtual returns (ICheatCodes _cheats);
}
