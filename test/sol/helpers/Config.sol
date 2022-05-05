//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IBeefyVaultV6} from "../../../lib/beefy/IBeefyVaultV6.sol";

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

        amount[0] = 100 * 1e18; // wFTM amount
        amount[1] = 100 * 1e6; // USDC amount
    }

    function getUniRouter() internal pure returns (IUniswapV2Router02 router) {
        // return IUniswapV2Router02(0x5023882f4D1EC10544FCB2066abE9C1645E95AA0); // WigoSwap router
        return IUniswapV2Router02(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52); // SpiritSwap router
        // return IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // SushiSwap router
        // return IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29); // Spookyswap router
    }

    function getUniFactory() internal pure returns (IUniswapV2Factory factory) {
        // return IUniswapV2Factory(0xC831A5cBfb4aC2Da5ed5B194385DFD9bF5bFcBa7); // WigoSwap factory
        return IUniswapV2Factory(0xEF45d134b73241eDa7703fa787148D9C9F4950b0); // SpiritSwap factory
        // return IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4); // SushiSwap factory
        // return IUniswapV2Factory(0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3); // Spookyswap factory
    }

    function getBeefyVault() internal pure returns (IBeefyVaultV6 beVault) {
        // return IBeefyVaultV6(0x70c6AF9Dff8C19B3db576E5E199B22A883874f05); // Beefy USDC-FTM LP WigoSwap
        return IBeefyVaultV6(0xA4e2EE5a7fF51224c27C98098D8DB5C770bAAdbE); // Beefy USDC-FTM LP SpiritSwap
        // return IBeefyVaultV6(0xb870e4755C737D2753D7298D0e70344077905Ed5); // Beefy USDC-FTM LP SushiSwap
        // return IBeefyVaultV6(0x41D44B276904561Ac51855159516FD4cB2c90968); // Beefy USDC-FTM LP Spookyswap
    }

    function getBeefyMasterChefVault() internal pure returns (IBeefyVaultV6 beVault) {}

    function getFos() internal pure returns (uint256 fosPercent, uint256 fosDenominator) {
        return (1, 100);
    }

    function getTAUInitialSupply() internal pure returns (uint256 initialSupply) {
        return 10000000 * 1e18;
    }

    function getTAUMintAmount() internal pure returns (uint256 mintAmount) {
        return 10 * 1e18;
    }

    function getFee() internal pure returns (uint256 feePercent, uint256 feeDenominator) {
        return (1, 1000);
    }
}
