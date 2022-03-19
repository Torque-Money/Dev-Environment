import {BigNumber, ethers} from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ERC20Upgradeable, LPool, MarginLong, Oracle, OracleTest} from "../../../typechain-types";

import {Config} from "../config/utilConfig";
import {ROUND_CONSTANT} from "../config/utilConstants";
import {getFilteredTokens} from "../tokens/utilGetTokens";
import {getTokenAmounts} from "../tokens/utilTokens";

// Add given tokens as collateral
export async function addCollateral(marginLong: MarginLong, tokens: ERC20Upgradeable[], amounts: ethers.BigNumber[]) {
    console.assert(tokens.length === amounts.length, "Length of tokens must equal length of amounts");

    for (let i = 0; i < tokens.length; i++) if (amounts[i].gt(0)) await (await marginLong.addCollateral(tokens[i].address, amounts[i])).wait();
}

// Get the minimum collateral required to satisfy collateral
export async function minCollateralAmount(account: string, marginLong: MarginLong, oracle: Oracle | OracleTest, tokens: ERC20Upgradeable[], fos: number = 0.2) {
    const fosNumerator = ROUND_CONSTANT + Math.floor(fos * ROUND_CONSTANT);
    const fosDenominator = ROUND_CONSTANT;

    const targetPrice = ethers.BigNumber.from(await marginLong.minCollateralPrice())
        .mul(fosNumerator)
        .div(fosDenominator);

    const available = await getTokenAmounts(account, tokens);
    const amounts = [];
    for (let i = 0; i < tokens.length; i++) {
        if (targetPrice.gt(0) && available[i].gt(0)) {
        } else amounts.push(ethers.BigNumber.from(0));
    }

    return await oracle.amountMax(token.address, minCollateralPrice);
}

// Remove collateral
export async function removeCollateral(marginLong: MarginLong, tokens: ERC20Upgradeable[], amounts: ethers.BigNumber[]) {
    console.assert(tokens.length === amounts.length, "Length of tokens must equal length of amounts");

    for (let i = 0; i < tokens.length; i++) if (amounts[i].gt(0)) await (await marginLong.removeCollateral(tokens[i].address, amounts[i])).wait();
}

// Remove all collateral
export async function removeAllCollateral(config: Config, hre: HardhatRuntimeEnvironment, marginLong: MarginLong) {
    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    const tokens = [];
    const amounts = [];
    for (const token of await getFilteredTokens(config, hre, "marginLongCollateral")) {
        const available = await marginLong.collateral(token.address, signerAddress);

        tokens.push(token);
        amounts.push(available);
    }

    await removeCollateral(marginLong, tokens, amounts);
}

// Calculate the max amount an account may borrow
export async function allowedBorrowAmount(hre: HardhatRuntimeEnvironment, marginLong: MarginLong, oracle: Oracle | OracleTest, pool: LPool, token: ERC20Upgradeable) {
    const ROUND_CONSTANT = 1e4;
    const SAFETY_REDUCTION = 2;

    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    const collateralPrice = await marginLong.collateralPrice(signerAddress);
    const currentPriceBorrowed = await marginLong["initialBorrowPrice(address)"](signerAddress);

    const [maxLeverageNumerator, maxLeverageDenominator] = await marginLong.maxLeverage();
    const maxLeverage = maxLeverageNumerator.mul(ROUND_CONSTANT).div(maxLeverageDenominator).toNumber() / ROUND_CONSTANT;

    let price;
    if (currentPriceBorrowed.gt(0)) {
        const [currentLeverageNumerator, currentLeverageDenominator] = await marginLong.currentLeverage(signerAddress);
        const currentLeverage = currentLeverageNumerator.mul(ROUND_CONSTANT).div(currentLeverageDenominator).toNumber() / ROUND_CONSTANT;

        const numerator = Math.floor((maxLeverage / currentLeverage - 1) * ROUND_CONSTANT);
        const denominator = ROUND_CONSTANT;

        price = ethers.BigNumber.from(numerator).mul(currentPriceBorrowed).div(denominator);
    } else {
        const numerator = Math.floor(maxLeverage * ROUND_CONSTANT);
        const denominator = ROUND_CONSTANT;

        price = collateralPrice.mul(numerator).div(denominator);
    }

    const liquidity = await pool.liquidity(token.address);
    const maxAllowed: BigNumber = await oracle.amountMin(token.address, price);

    let allowed;
    if (liquidity.gt(maxAllowed)) allowed = liquidity;
    else allowed = maxAllowed;

    return allowed.div(SAFETY_REDUCTION);
}
