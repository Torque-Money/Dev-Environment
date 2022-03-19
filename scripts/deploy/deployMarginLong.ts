import {HardhatRuntimeEnvironment} from "hardhat/types";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

import {chooseConfig, ConfigType, saveConfig} from "../utils/config/utilConfig";
import {saveTempConstructor} from "../utils/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    // Deploy contract with constructor args
    const constructorArgs = {
        pool: hre.ethers.constants.AddressZero,
        oracle: hre.ethers.constants.AddressZero,
        minCollateralPrice: config.setup.marginLong.minCollateralPrice,
        maxLeverageNumerator: config.setup.marginLong.maxLeverageNumerator,
        maxLeverageDenominator: config.setup.marginLong.maxLeverageDenominator,
        liquidationFeePercentNumerator: config.setup.marginLong.liquidationFeePercentNumerator,
        liquidationFeePercentDenominator: config.setup.marginLong.liquidationFeePercentDenominator,
    };
    const MarginLong = await hre.ethers.getContractFactory("MarginLong");
    const marginLong = await hre.upgrades.deployProxy(MarginLong, Object.values(constructorArgs));
    await marginLong.deployed();

    // Save in the config
    config.contracts.marginLongAddress = marginLong.address;
    const implementation = await getImplementationAddress(hre.ethers.provider, marginLong.address);
    console.log(`Deployed: MarginLong, implementation | ${marginLong.address}, ${implementation}`);

    if (configType !== "fork") saveTempConstructor(implementation, {});
    saveConfig(config, configType);
}
