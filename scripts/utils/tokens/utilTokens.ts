import {ethers} from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ERC20Upgradeable, LPool} from "../../../typechain-types";

import {chooseConfig, ConfigType} from "../config/utilConfig";

// Get an allowed amount of tokens to use
export async function getTokenAmount(hre: HardhatRuntimeEnvironment, tokens: ERC20Upgradeable[]) {
    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    const DISTRIBUTE_NUMERATOR = 25;
    const DISTRIBUTE_DENOMINATOR = 100;

    const amounts: ethers.BigNumber[] = [];
    for (const token of tokens) amounts.push((await token.balanceOf(signerAddress)).mul(DISTRIBUTE_NUMERATOR).div(DISTRIBUTE_DENOMINATOR));

    return amounts;
}

// Get an approved token from its address
export function getApprovedToken(configType: ConfigType, address: string) {
    const config = chooseConfig(configType);

    const approved = config.tokens.approved.filter((token) => token.address.toLowerCase() === address.toLowerCase());
    if (approved.length === 0) throw Error("No approved token with this address");

    return approved[0];
}

// Get the LP token from a pool token
export async function LPFromPT(hre: HardhatRuntimeEnvironment, pool: LPool, token: ERC20Upgradeable) {
    return await hre.ethers.getContractAt("LPoolToken", await pool.LPFromPT(token.address));
}
