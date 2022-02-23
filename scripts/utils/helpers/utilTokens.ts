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
    for (const approved of config.tokens.approved.filter((approved) => approved.leveragePool)) {
        tokens.push({token: await hre.ethers.getContractAt("ERC20", approved.address), raw: approved});
    }

    return tokens;
}

// **** In here we need to manually select the tokens we wish to choose

export async function getLPTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment, pool: LPool) {
    const tokens = await getPoolTokens(configType, hre);

    const lpTokens: LPoolToken[] = [];
    for (const {token} of tokens) {
        const lpAddress = await pool.LPFromPT(token.address);
        lpTokens.push(await hre.ethers.getContractAt("LPoolToken", lpAddress));
    }

    return lpTokens;
}

export async function getMarginLongCollateralTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: Token[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.marginLongCollateral)) {
        tokens.push({token: await hre.ethers.getContractAt("ERC20", approved.address), raw: approved});
    }

    return tokens;
}

export async function getMarginLongBorrowTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: Token[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.marginLongBorrow)) {
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
