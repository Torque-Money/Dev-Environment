import {HardhatRuntimeEnvironment} from "hardhat/types";
import {LPool} from "../../../typechain-types";
import {chooseConfig, ConfigType} from "../utilConfig";

export async function redeemLiquidity(configType: ConfigType, hre: HardhatRuntimeEnvironment, pool: LPool) {
    const config = chooseConfig(configType);

    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    for (const address of config.tokens.lpTokens.tokens) {
        const token = await hre.ethers.getContractAt("LPoolToken", address);
        const balance = await token.balanceOf(signerAddress);
        if (balance.gt(0)) await (await pool.redeemLiquidity(address, balance)).wait();
    }
}
