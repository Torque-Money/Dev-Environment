import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const constructorArgs = {
        pokeMe: config.gelatoPokeMe,
        marginLong: config.marginLongAddress,
        pool: config.leveragePoolAddress,
        converter: config.converterAddress,
    };
    const Resolver = await hre.ethers.getContractFactory("Resolver");
    const resolver = await Resolver.deploy(constructorArgs.pokeMe, constructorArgs.marginLong, constructorArgs.pool, constructorArgs.converter);
    await resolver.deployed();

    config.resolverAddress = resolver.address;
    console.log(`Deployed: Resolver | ${resolver.address}`);

    if (configType !== "fork") saveTempConstructor(resolver.address, constructorArgs);
    saveConfig(config, configType);
}
