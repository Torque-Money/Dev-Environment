import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    if (configType !== "fork") {
        const constructorArgs = {
            thresholdNumerator: 1,
            thresholdDenominator: 200,
            priceDecimals: 18,
        };

        const Oracle = await hre.ethers.getContractFactory("Oracle");
        const oracle = await Oracle.deploy(constructorArgs.thresholdNumerator, constructorArgs.thresholdDenominator, constructorArgs.priceDecimals);

        config.oracleAddress = oracle.address;
        console.log(`Deployed: Oracle | ${oracle.address}`);

        saveTempConstructor(oracle.address, constructorArgs);
    } else {
        const constructorArgs = {
            thresholdNumerator: 1,
            thresholdDenominator: 200,
            priceDecimals: 18,
        };

        const OracleTest = await hre.ethers.getContractFactory("OracleTest");
        const oracle = await OracleTest.deploy(constructorArgs.thresholdNumerator, constructorArgs.thresholdDenominator, constructorArgs.priceDecimals);

        config.oracleAddress = oracle.address;
        console.log(`Deployed: Oracle test | ${oracle.address}`);
    }

    saveConfig(config, configType);
}
