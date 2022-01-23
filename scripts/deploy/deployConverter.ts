import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const constructorArgs = {
        router: config.routerAddress,
    };

    const Converter = await hre.ethers.getContractFactory("Converter");
    const converter = await Converter.deploy(constructorArgs.router);
    config.converterAddress = converter.address;
    console.log(`Deployed: Converter | ${converter.address}`);

    if (configType !== "fork") saveTempConstructor(converter.address, constructorArgs);
    saveConfig(config, configType);
}
