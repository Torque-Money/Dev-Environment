import {HardhatRuntimeEnvironment} from "hardhat/types";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

import {chooseConfig, ConfigType, saveConfig} from "../utils/config/utilConfig";
import {saveTempConstructor} from "../utils/misc/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    // Deploy contract with constructor args
    const constructorArgs = {
        minDelay: config.setup.timelock.minDelay,
        proposers: config.setup.timelock.proposers.length > 0 ? config.setup.timelock.proposers : [signerAddress],
        executors: [hre.ethers.constants.AddressZero],
    };
    const Timelock = await hre.ethers.getContractFactory("Timelock");
    const timelock = await hre.upgrades.deployProxy(Timelock, Object.values(constructorArgs));
    await timelock.deployed();

    // Save in the config
    config.contracts.timelockAddress = timelock.address;
    const implementation = await getImplementationAddress(hre.ethers.provider, timelock.address);
    console.log(`Deployed: Timelock, implementation | ${timelock.address} ${implementation}`);

    if (configType !== "fork") saveTempConstructor(implementation, {});
    saveConfig(config, configType);
}
