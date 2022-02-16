import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    if (configType === "main") {
        const constructorArgs = {
            thresholdNumerator: 1,
            thresholdDenominator: 200,
            priceDecimals: 18,
        };

        const Oracle = await hre.ethers.getContractFactory("Oracle");
        const oracle = await Oracle.deploy(constructorArgs.thresholdNumerator, constructorArgs.thresholdDenominator, constructorArgs.priceDecimals);
        await oracle.deployed();

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
        const oracleTest = await OracleTest.deploy(constructorArgs.thresholdNumerator, constructorArgs.thresholdDenominator, constructorArgs.priceDecimals);
        await oracleTest.deployed();

        config.oracleAddress = oracleTest.address;
        console.log(`Deployed: Oracle test | ${oracleTest.address}`);

        if (configType !== "fork") saveTempConstructor(oracleTest.address, constructorArgs);
    }

    const constructorArgs = {
        oracle: config.oracleAddress,
        pool: config.leveragePoolAddress,
    };

    const OracleReserve = await hre.ethers.getContractFactory("OracleReserve");
    const oracleReserve = await OracleReserve.deploy(constructorArgs.oracle, constructorArgs.pool);
    await oracleReserve.deployed();

    config.oracleReserveAddress = oracleReserve.address;
    console.log(`Deployed: Oracle reserve | ${oracleReserve.address}`);

    if (configType !== "fork") saveTempConstructor(config.oracleReserveAddress, constructorArgs);

    saveConfig(config, configType);
}
