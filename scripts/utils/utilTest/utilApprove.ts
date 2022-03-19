import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../config/utilConfig";
import {getFilteredTokenAddresses} from "../tokens/utilGetTokens";

// Approve tokens to be used with the contracts
export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const approvedAmount = hre.ethers.BigNumber.from(2).pow(255);

    const wethAddress = config.tokens.wrappedCoin.address;
    const addresses = getFilteredTokenAddresses(config, null).filter((address) => address != wethAddress);
    addresses.push(wethAddress);

    for (const address of addresses) {
        const token = await hre.ethers.getContractAt("ERC20Upgradeable", address);

        await (await token.approve(config.contracts.leveragePoolAddress, approvedAmount)).wait();
        await (await token.approve(config.contracts.marginLongAddress, approvedAmount)).wait();
        await (await token.approve(config.contracts.flashLender, approvedAmount)).wait();
        await (await token.approve(config.contracts.converterAddress, approvedAmount)).wait();

        console.log(`Approve: Approved contracts to spend tokens with address ${address}`);
    }
}
