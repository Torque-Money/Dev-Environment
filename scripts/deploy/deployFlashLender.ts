import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const constructorArgs = {
        pool: config.leveragePoolAddress,
        feePercentNumerator: 1,
        feePercentDenominator: 1000000,
    };

    const FlashLender = await hre.ethers.getContractFactory("FlashLender");
    const flashLender = await FlashLender.deploy(constructorArgs.pool, constructorArgs.feePercentNumerator, constructorArgs.feePercentDenominator);
    await flashLender.deployed();

    config.flashLender = flashLender.address;
    console.log(`Deployed: FlashLender | ${flashLender.address}`);

    if (configType === "fork") {
        const constructorArgsBorrower = {
            lender: flashLender.address,
        };

        const FlashBorrower = await hre.ethers.getContractFactory("FlashBorrower");
        const flashBorrower = await FlashBorrower.deploy(constructorArgsBorrower.lender);
        await flashBorrower.deployed();

        config.flashBorrower = flashBorrower.address;
        console.log(`Deployed: FlashBorrower | ${flashBorrower.address}`);
    }

    if (configType !== "fork") saveTempConstructor(flashLender.address, constructorArgs);
    saveConfig(config, configType);
}
