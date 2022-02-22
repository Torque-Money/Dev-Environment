import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../utils/utilConfig";
import {saveTempConstructor} from "../utils/utilVerify";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    if (configType === "main") {
        const constructorArgs = {
            pool: config.contracts.leveragePoolAddress,
            thresholdNumerator: 1,
            thresholdDenominator: 200,
            priceDecimals: 18,
        };

        const Oracle = await hre.ethers.getContractFactory("Oracle");
        const oracle = await hre.upgrades.deployProxy(Oracle, Object.values(constructorArgs));
        await oracle.deployed();

        config.contracts.oracleAddress = oracle.address;
        const implementation = await getImplementationAddress(hre.ethers.provider, oracle.address);
        console.log(`Deployed: Oracle, implementation | ${oracle.address}, ${implementation}`);

        saveTempConstructor(implementation, {});
    } else {
        const constructorArgs = {
            pool: config.contracts.leveragePoolAddress,
            thresholdNumerator: 1,
            thresholdDenominator: 200,
            priceDecimals: 18,
        };

        const OracleTest = await hre.ethers.getContractFactory("OracleTest");
        const oracleTest = await hre.upgrades.deployProxy(OracleTest, Object.values(constructorArgs));
        await oracleTest.deployed();

        config.contracts.oracleAddress = oracleTest.address;
        const implementation = await getImplementationAddress(hre.ethers.provider, oracleTest.address);
        console.log(`Deployed: OracleTest, implementation | ${oracleTest.address}, ${implementation}`);

        if (configType !== "fork") saveTempConstructor(implementation, {});
    }

    saveConfig(config, configType);
}
