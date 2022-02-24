import {ethers} from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ERC20, MarginLong, Oracle} from "../../../typechain-types";
import {chooseConfig, ConfigType} from "../utilConfig";

export async function addCollateral(marginLong: MarginLong, tokens: ERC20[], amounts: ethers.BigNumber[]) {
    console.assert(tokens.length === amounts.length, "Length of tokens must equal length of amounts");

    for (let i = 0; i < tokens.length; i++) await (await marginLong.addCollateral(tokens[i].address, amounts[i])).wait();
}

export async function removeCollateral(configType: ConfigType, hre: HardhatRuntimeEnvironment, marginLong: MarginLong) {
    const config = chooseConfig(configType);

    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    for (const token of config.tokens.approved.filter((approved) => approved.marginLongCollateral)) {
        const available = await marginLong.collateral(token.address, signerAddress);
        if (available.gt(0)) await marginLong.removeCollateral(token.address, available);
    }
}

export async function borrow(marginLong: MarginLong, tokens: ERC20[], amounts: ethers.BigNumber[]) {
    console.assert(tokens.length === amounts.length, "Length of tokens must equal length of amounts");

    for (let i = 0; i < tokens.length; i++) await (await marginLong.borrow(tokens[i].address, amounts[i])).wait();
}

async function allowedBorrowAmount(hre: HardhatRuntimeEnvironment, marginLong: MarginLong, oracle: Oracle, token: ERC20) {
    const ROUND_CONSTANT = 1e4;

    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    const collateralPrice = await marginLong.collateralPrice(signerAddress);
    const currentPriceBorrowed = await marginLong["initialBorrowPrice(address)"](signerAddress);

    const [maxLeverageNumerator, maxLeverageDenominator] = await marginLong.maxLeverage();
    const maxLeverage = maxLeverageNumerator.mul(ROUND_CONSTANT).div(maxLeverageDenominator).toNumber() / ROUND_CONSTANT;

    const [currentLeverageNumerator, currentLeverageDenominator] = await marginLong.currentLeverage(signerAddress);
    const currentLeverage = currentLeverageNumerator.mul(ROUND_CONSTANT).div(currentLeverageDenominator).toNumber() / ROUND_CONSTANT;

    if (currentPriceBorrowed.gt(0)) {
        const numerator = Math.floor((maxLeverage / currentLeverage - 1) * ROUND_CONSTANT);
        const denominator = ROUND_CONSTANT;

        return ethers.BigNumber.from(numerator).mul(currentPriceBorrowed).div(denominator);
    } else {
        if (!collateralPrice) throw Error("Collateral price cannot be undefined");

        const numerator = Math.floor(maxLeverage * ROUND_CONSTANT);
        const denominator = ROUND_CONSTANT;

        return collateralPrice.mul(numerator).div(denominator);
    }
}
