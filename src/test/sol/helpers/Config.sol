//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICheatCodes} from "./ICheatCodes.sol";

// Configured for the Fantom Opera mainnet

library Config {
    function getCheatCodes() internal pure returns (ICheatCodes cheatCodes) {
        return ICheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    }

    function getToken() internal pure returns (IERC20[] memory token) {
        token = new IERC20[](2);

        token[0] = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83); // wFTM
        token[1] = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75); // USDC
    }

    function getTokenWhale() internal pure returns (address[] memory whale) {
        whale = new address[](2);

        assert(whale.length == getToken().length);

        whale[0] = 0x60a861Cd30778678E3d613db96139440Bd333143; // wFTM whale
        whale[1] = 0xc5ed2333f8a2C351fCA35E5EBAdb2A82F5d254C3; // USDC whale
    }

    function getTokenAmount() internal pure returns (uint256[] memory amount) {
        amount = new uint256[](2);

        assert(amount.length == getToken().length);

        amount[0] = 10 * 1e18; // wFTM amount
        amount[1] = 10 * 1e6; // USDC amount
    }

    function getInitialAPY() internal pure returns (uint256 apy) {
        apy = 20;
    }
}
