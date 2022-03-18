import {HardhatRuntimeEnvironment} from "hardhat/types";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

import {chooseConfig, ConfigType, saveConfig} from "../utils/config/utilConfig";
import {saveTempConstructor} from "../utils/misc/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const constructorArgs = {
        router: config.setup.converter.routerAddress,
    };

    const Converter = await hre.ethers.getContractFactory("Converter");
    const converter = await hre.upgrades.deployProxy(Converter, Object.values(constructorArgs));
    await converter.deployed();

    config.contracts.converterAddress = converter.address;
    const implementation = await getImplementationAddress(hre.ethers.provider, converter.address);
    console.log(`Deployed: Converter, implementation | ${converter.address}, ${implementation}`);

    if (configType !== "fork") saveTempConstructor(implementation, {});
    saveConfig(config, configType);
}
