import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ERC20Upgradeable, LPoolToken} from "../../../typechain-types";

import {chooseConfig, Config, ConfigType} from "../config/utilConfig";

type Filter = "leveragePool" | "marginLongBorrow" | "marginLongCollateral" | "flashLender" | "oracle";

// Get filtered approved tokens
export function getFilteredApprovedTokens(config: Config, filter: Filter) {
    return config.tokens.approved.filter((approved) => approved.setup && approved.setup[filter]);
}

// Get token address filted by approved configuration
export function getFilteredTokenAddresses(config: Config, filter: Filter) {
    return getFilteredApprovedTokens(config, filter).map((approved) => approved.address);
}

// Get tokens filtered by their approved configuration
export async function getFilteredTokens(
    config: Config,
    hre: HardhatRuntimeEnvironment,
    filter: "leveragePool" | "marginLongBorrow" | "marginLongCollateral" | "flashLender" | "oracle"
) {
    let tokens: ERC20Upgradeable[] = [];
    for (const address of getFilteredTokenAddresses(config, filter)) tokens.push(await hre.ethers.getContractAt("ERC20Upgradeable", address));

    return tokens;
}

// Get a list of LP tokens
export async function getLPTokens(config: Config, hre: HardhatRuntimeEnvironment) {
    let tokens: LPoolToken[] = [];
    for (const approved of config.tokens.lpTokens.tokens) tokens.push(await hre.ethers.getContractAt("LPoolToken", approved));

    return tokens;
}
