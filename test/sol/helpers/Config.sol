//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IBeefyVaultV6} from "../../../src/interfaces/beefy/IBeefyVaultV6.sol";

// Configured for the Fantom Opera mainnet

library Config {
    function getToken() internal pure returns (IERC20Upgradeable[] memory token) {
        token = new IERC20Upgradeable[](2);

        token[0] = IERC20Upgradeable(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83); // wFTM
        token[1] = IERC20Upgradeable(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75); // USDC
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

    function getUniRouter() internal pure returns (IUniswapV2Router02 router) {
        return IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29); // Spookyswap router
    }

    function getUniFactory() internal pure returns (IUniswapV2Factory factory) {
        return IUniswapV2Factory(0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3); // Spookyswap factory
    }

    function getBeefyVault() internal pure returns (IBeefyVaultV6 beVault) {
        return IBeefyVaultV6(0x41D44B276904561Ac51855159516FD4cB2c90968); // Beefy USDC-FTM LP Spookyswap
    }

    function getFosPercent() internal pure returns (uint256 fosPercent) {
        return 5;
    }

    function getFosDenominator() internal pure returns (uint256 fosPercent) {
        return 1000;
    }
}
