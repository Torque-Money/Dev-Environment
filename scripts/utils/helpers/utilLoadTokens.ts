import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType} from "../utilConfig";

import {ERC20} from "../../../typechain-types";

interface Token {
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
