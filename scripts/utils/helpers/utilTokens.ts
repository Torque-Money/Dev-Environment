import {HardhatRuntimeEnvironment} from "hardhat/types";
import {ethers} from "ethers";

import {chooseConfig, ConfigType} from "../utilConfig";
import {ERC20, LPool, LPoolToken} from "../../../typechain-types";

export interface Token {
    token: ERC20;
    raw: any;
}

export async function getPoolTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: Token[] = [];
    // **** Get the tokens that are not in the collateral tokens list
    for (const approved of config.tokens.approved.filter((approved) => approved.leveragePool && !approved.marginLongCollateral)) {
        tokens.push({token: await hre.ethers.getContractAt("ERC20", approved.address), raw: approved});
    }

    return tokens;
}

export async function getCollateralTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: Token[] = [];
    // **** Get the tokens that are not in the pool tokens list
    for (const approved of config.tokens.approved.filter((approved) => approved.marginLongCollateral && !approved.leveragePool)) {
        tokens.push({token: await hre.ethers.getContractAt("ERC20", approved.address), raw: approved});
    }

    return tokens;
}

export async function getFlashLenderTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: Token[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.flashLender)) {
        tokens.push({token: await hre.ethers.getContractAt("ERC20", approved.address), raw: approved});
    }

    return tokens;
}

export async function getOracleTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: Token[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.oracle)) {
        tokens.push({token: await hre.ethers.getContractAt("ERC20", approved.address), raw: approved});
    }

    return tokens;
}

export async function getTokenAmount(hre: HardhatRuntimeEnvironment, tokens: ERC20[]) {
    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    const distributeAmount = 3; // Pool, collateral, borrow

    const amounts: ethers.BigNumber[] = [];
    for (const token of tokens) amounts.push((await token.balanceOf(signerAddress)).div(distributeAmount));

    return amounts;
}
