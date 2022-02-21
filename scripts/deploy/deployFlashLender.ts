import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../utils/utilConfig";
import {saveTempConstructor} from "../utils/utilVerify";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const constructorArgs = {
        pool: config.contracts.leveragePoolAddress,
        feePercentNumerator: 1,
        feePercentDenominator: 1000000,
    };

    const FlashLender = await hre.ethers.getContractFactory("FlashLender");
    const flashLender = await hre.upgrades.deployProxy(FlashLender, Object.values(constructorArgs));
    await flashLender.deployed();

    config.contracts.flashLender = flashLender.address;
    const implementation = await getImplementationAddress(hre.ethers.provider, flashLender.address);
    console.log(`Deployed: FlashLender, implementation | ${flashLender.address}, ${implementation}`);

    if (configType === "fork") {
        const FlashBorrowerTest = await hre.ethers.getContractFactory("FlashBorrowerTest");
        const flashBorrowerTest = await hre.upgrades.deployProxy(FlashBorrowerTest);
        await flashBorrowerTest.deployed();

        config.contracts.flashBorrowerTest = flashBorrowerTest.address;
        const implementation = await getImplementationAddress(hre.ethers.provider, flashBorrowerTest.address);
        console.log(`Deployed: FlashBorrowerTest, implementation | ${flashBorrowerTest.address}, ${implementation}`);
    }

    if (configType !== "fork") saveTempConstructor(implementation, {});
    saveConfig(config, configType);
}
