import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ERC20Upgradeable, LPoolToken} from "../../../typechain-types";

import {chooseConfig, ConfigType} from "../config/utilConfig";

// Filter tokens by their approved configuration
export async function filter(
    configType: ConfigType,
    hre: HardhatRuntimeEnvironment,
    by: "leveragePool" | "marginLongBorrow" | "marginLongCollateral" | "flashLender" | "oracle"
) {
    const config = chooseConfig(configType);

    let tokens: ERC20Upgradeable[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.setup[by])) {
        tokens.push(await hre.ethers.getContractAt("ERC20Upgradeable", approved.address));
    }

    return tokens;
}

// Get a list of LP tokens
export async function getLPTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: LPoolToken[] = [];
    for (const approved of config.tokens.lpTokens.tokens) {
        tokens.push(await hre.ethers.getContractAt("LPoolToken", approved));
    }

    return tokens;
}
