import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../utils/config/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const resolver = await hre.ethers.getContractAt("Resolver", config.contracts.resolverAddress);

    // Setup the contracts of which the resolver uses
    await (await resolver.setMarginLong(config.contracts.marginLongAddress)).wait();
    console.log("-- Set margin long");
    await (await resolver.setConverter(config.contracts.converterAddress)).wait();
    console.log("-- Set converter");

    console.log("Setup: MarginLong");
}
