import {HardhatRuntimeEnvironment} from "hardhat/types";
import {ethers} from "ethers";

import {chooseConfig, ConfigType} from "../utilConfig";
import {ERC20, LPool} from "../../../typechain-types";

export async function getPoolTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: ERC20[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.leveragePool)) {
        tokens.push(await hre.ethers.getContractAt("ERC20", approved.address));
    }

    return tokens;
}

export async function getCollateralTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: ERC20[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.marginLongCollateral && !approved.leveragePool)) {
        tokens.push(await hre.ethers.getContractAt("ERC20", approved.address));
    }

    return tokens;
}

export async function LPFromPT(hre: HardhatRuntimeEnvironment, pool: LPool, token: ERC20) {
    return await hre.ethers.getContractAt("LPoolToken", await pool.LPFromPT(token.address));
}

export async function getFlashLenderTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: ERC20[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.flashLender)) {
        tokens.push(await hre.ethers.getContractAt("ERC20", approved.address));
    }

    return tokens;
}

export async function getOracleTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: ERC20[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.oracle)) {
        tokens.push(await hre.ethers.getContractAt("ERC20", approved.address));
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

export async function logTokenAmounts(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    for (const {address} of config.tokens.approved) {
        const token = await hre.ethers.getContractAt("ERC20", address);
        console.log(await token.balanceOf(signerAddress));
    }
}
