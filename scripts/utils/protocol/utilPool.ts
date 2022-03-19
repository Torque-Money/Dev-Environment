import {ethers} from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ERC20Upgradeable, LPool, LPoolToken} from "../../../typechain-types";
import {Config} from "../config/utilConfig";
import {getLPTokens} from "../tokens/utilGetTokens";
import {getTokenAmounts} from "../tokens/utilTokens";

// Provide liquidity to the protocol
export async function provideLiquidity(pool: LPool, tokens: ERC20Upgradeable[], amounts: ethers.BigNumber[]) {
    console.assert(tokens.length === amounts.length, "Length of tokens must equal length of amounts");

    for (let i = 0; i < tokens.length; i++) await (await pool.provideLiquidity(tokens[i].address, amounts[i])).wait();
}

// Redeem liquidity from the protocol
export async function redeemLiquidity(pool: LPool, lpTokens: LPoolToken[], amounts: ethers.BigNumber[]) {
    console.assert(lpTokens.length === amounts.length, "Length of tokens must equal length of amounts");

    for (let i = 0; i < lpTokens.length; i++) if (amounts[i].gt(0)) await (await pool.redeemLiquidity(lpTokens[i].address, amounts[i])).wait();
}

// Remove all liquidity from the protocol
export async function redeemAllLiquidity(config: Config, hre: HardhatRuntimeEnvironment, pool: LPool) {
    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    const lpTokens = await getLPTokens(config, hre);
    const available = await getTokenAmounts(signerAddress, lpTokens);

    await redeemLiquidity(pool, lpTokens, available);
}
