import {HardhatRuntimeEnvironment} from "hardhat/types";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

import {chooseConfig, ConfigType, saveConfig} from "../utils/config/utilConfig";
import {saveTempConstructor} from "../utils/deployment/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    // Deploy contract with constructor args
    const constructorArgs = {
        taskTreasury: config.setup.resolver.taskTreasury,
        depositReceiver: config.setup.resolver.depositReceiver.length > 0 ? config.setup.resolver.depositReceiver : signerAddress,
        ethAddress: config.setup.resolver.ethAddress,
        marginLong: hre.ethers.constants.AddressZero,
        converter: hre.ethers.constants.AddressZero,
    };
    const Resolver = await hre.ethers.getContractFactory("Resolver");
    const resolver = await hre.upgrades.deployProxy(Resolver, Object.values(constructorArgs));
    await resolver.deployed();

    // Save in the config
    config.contracts.resolverAddress = resolver.address;
    const implementation = await getImplementationAddress(hre.ethers.provider, resolver.address);
    console.log(`Deployed: Resolver, implementation | ${resolver.address}, ${implementation}`);

    if (configType !== "fork") saveTempConstructor(implementation, {});
    saveConfig(config, configType);
}
