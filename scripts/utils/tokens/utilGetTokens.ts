import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ERC20Upgradeable, LPoolToken} from "../../../typechain-types";

import {chooseConfig, ConfigType} from "../config/utilConfig";

type Filter = "leveragePool" | "marginLongBorrow" | "marginLongCollateral" | "flashLender" | "oracle";

// Get filtered approved tokens
export function getFilteredApprovedTokens(configType: ConfigType, filter: Filter) {
    const config = chooseConfig(configType);

    return config.tokens.approved.filter((approved) => approved.setup[filter]);
}

// Get token address filted by approved configuration
export function getFilteredTokenAddresses(configType: ConfigType, filter: Filter) {
    return getFilteredApprovedTokens(configType, filter).map((approved) => approved.address);
}

// Get tokens filtered by their approved configuration
export async function getFilteredTokens(
    configType: ConfigType,
    hre: HardhatRuntimeEnvironment,
    filter: "leveragePool" | "marginLongBorrow" | "marginLongCollateral" | "flashLender" | "oracle"
) {
    let tokens: ERC20Upgradeable[] = [];
    for (const address of getFilteredTokenAddresses(configType, filter)) tokens.push(await hre.ethers.getContractAt("ERC20Upgradeable", address));

    return tokens;
}

// Get a list of LP tokens
export async function getLPTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: LPoolToken[] = [];
    for (const approved of config.tokens.lpTokens.tokens) tokens.push(await hre.ethers.getContractAt("LPoolToken", approved));

    return tokens;
}
