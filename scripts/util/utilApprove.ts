import ERC20Abi from "@openzeppelin/contracts/build/contracts/ERC20.json";
import {chooseConfig, ConfigType} from "./utilConfig";
import {HardhatRuntimeEnvironment} from "hardhat/types";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const approvedAmount = hre.ethers.BigNumber.from(2).pow(255);

    for (const approved of config.approved) {
        const token = await hre.ethers.getContractAt("ERC20", approved.address);

        await (await token.approve(config.leveragePoolAddress, approvedAmount)).wait();
        await (await token.approve(config.marginLongAddress, approvedAmount)).wait();
        await (await token.approve(config.flashBorrower, approvedAmount)).wait();

        console.log(`Approve: Approved contracts to spend tokens with address ${approved.address}`);
    }

    const weth = await hre.ethers.getContractAt("ERC20", config.wrappedCoin.address);

    await (await weth.approve(config.leveragePoolAddress, approvedAmount)).wait();
    await (await weth.approve(config.marginLongAddress, approvedAmount)).wait();

    console.log(`Approve: Approved contracts to spend tokens with address ${weth.address}`);
}
