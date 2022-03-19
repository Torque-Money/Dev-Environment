import {ethers} from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ERC20Upgradeable, LPool} from "../../../typechain-types";
import {Config} from "../config/utilConfig";
import {getLPTokenAddresses} from "../tokens/utilGetTokens";

// Provide liquidity to the protocol
export async function provideLiquidity(pool: LPool, tokens: ERC20Upgradeable[], amounts: ethers.BigNumber[]) {
    console.assert(tokens.length === amounts.length, "Length of tokens must equal length of amounts");

    for (let i = 0; i < tokens.length; i++) await (await pool.provideLiquidity(tokens[i].address, amounts[i])).wait();
}

// Redeem liquidity from the protocol
export async function redeemLiquidity(pool: LPool, lpTokens: ERC20Upgradeable[], amounts: ethers.BigNumber[]) {}

// Remove all liquidity from the protocol
export async function redeemAllLiquidity(config: Config, hre: HardhatRuntimeEnvironment, pool: LPool) {
    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    for (const address of getLPTokenAddresses(config)) {
        const token = await hre.ethers.getContractAt("LPoolToken", address);
        const balance = await token.balanceOf(signerAddress);
        if (balance.gt(0)) await (await pool.redeemLiquidity(address, balance)).wait();
    }
}
