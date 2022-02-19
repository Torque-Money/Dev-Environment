import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../utils/utilConfig";
import {saveTempConstructor} from "../utils/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const constructorArgs = {
        taskTreasury: config.taskTreasury,
        depositReceiver: signerAddress,
        ethAddress: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
        marginLong: config.marginLongAddress,
        converter: config.converterAddress,
    };
    const Resolver = await hre.ethers.getContractFactory("Resolver");
    const resolver = await Resolver.deploy(
        constructorArgs.taskTreasury,
        constructorArgs.depositReceiver,
        constructorArgs.ethAddress,
        constructorArgs.marginLong,
        constructorArgs.converter
    );
    await resolver.deployed();

    config.resolverAddress = resolver.address;
    console.log(`Deployed: Resolver | ${resolver.address}`);

    if (configType !== "fork") saveTempConstructor(resolver.address, constructorArgs);
    saveConfig(config, configType);
}
