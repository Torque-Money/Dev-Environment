import {BigNumber, Contract, ethers} from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ERC20Upgradeable, LPool, MarginLong} from "../../../typechain-types";
import {chooseConfig, ConfigType} from "../config/utilConfig";
import {getFilteredTokens} from "../tokens/utilGetTokens";

// Add given tokens as collateral
export async function addCollateral(marginLong: MarginLong, tokens: ERC20Upgradeable[], amounts: ethers.BigNumber[]) {
    console.assert(tokens.length === amounts.length, "Length of tokens must equal length of amounts");

    for (let i = 0; i < tokens.length; i++) await (await marginLong.addCollateral(tokens[i].address, amounts[i])).wait();
}

// Remove all collateral
export async function removeCollateral(configType: ConfigType, hre: HardhatRuntimeEnvironment, marginLong: MarginLong) {
    const config = chooseConfig(configType);

    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    for (const token of await getFilteredTokens(configType, hre, "marginLongCollateral")) {
        const available = await marginLong.collateral(token.address, signerAddress);
        if (available.gt(0)) await marginLong.removeCollateral(token.address, available);
    }
}

// Get the minimum collateral required to satisfy collateral
export async function minCollateralAmount(marginLong: MarginLong, oracle: Contract, token: ERC20Upgradeable) {
    const minCollateralPrice = (await marginLong.minCollateralPrice()).mul(120).div(100);
    return await oracle.amountMax(token.address, minCollateralPrice);
}

// Calculate the max amount an account may borrow
export async function allowedBorrowAmount(hre: HardhatRuntimeEnvironment, marginLong: MarginLong, oracle: Contract, pool: LPool, token: ERC20Upgradeable) {
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
