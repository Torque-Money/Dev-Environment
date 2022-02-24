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

async function allowedBorrowAmount(marginLong: MarginLong, oracle: Oracle, token: ERC20) {
    // **** Make a function used to calculate the max leverage level
}
