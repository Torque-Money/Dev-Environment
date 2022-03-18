import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../config/utilConfig";

// Approve tokens to be used with the contracts
export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const approvedAmount = hre.ethers.BigNumber.from(2).pow(255);

    for (const approved of config.tokens.approved) {
        const token = await hre.ethers.getContractAt("ERC20Upgradeable", approved.address);

        await (await token.approve(config.contracts.leveragePoolAddress, approvedAmount)).wait();
        await (await token.approve(config.contracts.marginLongAddress, approvedAmount)).wait();
        await (await token.approve(config.contracts.flashLender, approvedAmount)).wait();
        await (await token.approve(config.contracts.converterAddress, approvedAmount)).wait();

        console.log(`Approve: Approved contracts to spend tokens with address ${approved.address}`);
    }

    const weth = await hre.ethers.getContractAt("ERC20Upgradeable", config.tokens.wrappedCoin.address);

    await (await weth.approve(config.contracts.leveragePoolAddress, approvedAmount)).wait();
    await (await weth.approve(config.contracts.marginLongAddress, approvedAmount)).wait();
    await (await weth.approve(config.contracts.flashLender, approvedAmount)).wait();
    await (await weth.approve(config.contracts.converterAddress, approvedAmount)).wait();

    console.log(`Approve: Approved contracts to spend tokens with address ${weth.address}`);
}
