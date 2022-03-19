import {ethers} from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ERC20Upgradeable, LPool} from "../../../typechain-types";

import {chooseConfig, ConfigType} from "../config/utilConfig";
import {ROUND_CONSTANT} from "../config/utilConstants";

// Get an allowed amount of tokens to use
export async function getTokenAmounts(account: string, tokens: ERC20Upgradeable[], fos: number = 0) {
    const fosNumerator = ROUND_CONSTANT - Math.floor(fos * ROUND_CONSTANT);
    const fosDenominator = ROUND_CONSTANT;

    const amounts: ethers.BigNumber[] = [];
    for (const token of tokens) amounts.push((await token.balanceOf(account)).mul(fosNumerator).div(fosDenominator));

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
