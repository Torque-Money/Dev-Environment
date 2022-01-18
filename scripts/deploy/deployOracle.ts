import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, saveConfig} from "../util/chooseConfig";

export default async function main(test: boolean, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(test);

    const constructorArgs = {
        thresholdNumerator: 1,
        thresholdDenominator: 200,
        priceDecimals: 18,
    };
    const Oracle = await hre.ethers.getContractFactory("Oracle");
    const oracle = await Oracle.deploy(constructorArgs.thresholdNumerator, constructorArgs.thresholdDenominator, constructorArgs.priceDecimals);
    config.oracleAddress = oracle.address;
    console.log("Deployed: Oracle");

    saveConfig(config, test);
}
