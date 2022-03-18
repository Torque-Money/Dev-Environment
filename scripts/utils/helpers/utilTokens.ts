import {HardhatRuntimeEnvironment} from "hardhat/types";
import {ethers} from "ethers";

import {chooseConfig, ConfigType} from "../utilConfig";
import {ERC20Upgradeable, LPool, LPoolToken} from "../../../typechain-types";

// Get a list of borrow tokens
export async function getBorrowTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: ERC20Upgradeable[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.setup.marginLongBorrow)) {
        tokens.push(await hre.ethers.getContractAt("ERC20Upgradeable", approved.address));
    }

    return tokens;
}

// Get a list of collateral tokens
export async function getCollateralTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: ERC20Upgradeable[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.setup.marginLongCollateral && !approved.setup.leveragePool)) {
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

// Get the LP token from a pool token
export async function LPFromPT(hre: HardhatRuntimeEnvironment, pool: LPool, token: ERC20Upgradeable) {
    return await hre.ethers.getContractAt("LPoolToken", await pool.LPFromPT(token.address));
}

// Get a list of flash lender tokens
export async function getFlashLenderTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: ERC20Upgradeable[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.setup.flashLender)) {
        tokens.push(await hre.ethers.getContractAt("ERC20Upgradeable", approved.address));
    }

    return tokens;
}

// Get a list of oracle tokens
export async function getOracleTokens(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let tokens: ERC20Upgradeable[] = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.setup.oracle)) {
        tokens.push(await hre.ethers.getContractAt("ERC20Upgradeable", approved.address));
    }

    return tokens;
}

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
