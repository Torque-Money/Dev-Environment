import {ethers} from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {ERC20, LPool} from "../../../typechain-types";
import {chooseConfig, ConfigType} from "../utilConfig";

export async function provideLiquidity(pool: LPool, tokens: ERC20[], amounts: ethers.BigNumber[]) {
    console.assert(tokens.length === amounts.length, "Length of tokens must equal length of amounts");

    for (let i = 0; i < tokens.length; i++) await (await pool.provideLiquidity(tokens[i].address, amounts[i])).wait();
}

export async function redeemLiquidity(configType: ConfigType, hre: HardhatRuntimeEnvironment, pool: LPool) {
    const config = chooseConfig(configType);

    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    for (const address of config.tokens.lpTokens.tokens) {
        const token = await hre.ethers.getContractAt("LPoolToken", address);
        const balance = await token.balanceOf(signerAddress);
        if (balance.gt(0)) await (await pool.redeemLiquidity(address, balance)).wait();
    }
}
