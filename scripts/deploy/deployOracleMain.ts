import {HardhatRuntimeEnvironment} from "hardhat/types";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

import {chooseConfig, ConfigType, saveConfig} from "../utils/config/utilConfig";
import {saveTempConstructor} from "../utils/misc/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    // Deploy contract with constructor args
    const constructorArgs = {
        pool: hre.ethers.constants.AddressZero,
        priceDecimals: config.setup.oracle.priceDecimals,
        thresholdNumerator: config.setup.oracle.thresholdNumerator,
        thresholdDenominator: config.setup.oracle.thresholdDenominator,
    };
    const Oracle = await hre.ethers.getContractFactory("Oracle");
    const oracle = await hre.upgrades.deployProxy(Oracle, Object.values(constructorArgs));
    await oracle.deployed();

    // Save in the config
    config.contracts.oracleAddress = oracle.address;
    const implementation = await getImplementationAddress(hre.ethers.provider, oracle.address);
    console.log(`Deployed: Oracle, implementation | ${oracle.address}, ${implementation}`);

    if (configType != "fork") saveTempConstructor(implementation, {});
    saveConfig(config, configType);
}
