import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, saveConfig} from "../util/chooseConfig";

export default async function main(test: boolean, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(test);

    const constructorArgs = {
        pokeMe: config.gelatoPokeMe,
        marginLong: config.marginLongAddress,
        pool: config.leveragePoolAddress,
        converter: config.converterAddress,
    };
    const Resolver = await hre.ethers.getContractFactory("Resolver");
    const resolver = await Resolver.deploy(...Object.values(constructorArgs));
    config.resolverAddress = resolver.address;
    console.log("Deployed: Resolver");

    saveConfig(config, test);
}
