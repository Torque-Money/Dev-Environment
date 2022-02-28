import {HardhatRuntimeEnvironment} from "hardhat/types";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

import {chooseConfig, ConfigType, saveConfig} from "../utils/utilConfig";
import {saveTempConstructor} from "../utils/utilVerify";
import {chainSleep, SLEEP_SECONDS} from "../utils/chainTypeSleep";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const constructorArgs = {
        minDelay: configType === "test" ? hre.ethers.BigNumber.from(3) : hre.ethers.BigNumber.from(64800),
        proposers: [signerAddress],
        executors: [hre.ethers.constants.AddressZero],
    };

    const Timelock = await hre.ethers.getContractFactory("Timelock");
    const timelock = await hre.upgrades.deployProxy(Timelock, Object.values(constructorArgs));
    await timelock.deployed();
    await chainSleep(configType, SLEEP_SECONDS);

    config.contracts.timelockAddress = timelock.address;
    const implementation = await getImplementationAddress(hre.ethers.provider, timelock.address);
    console.log(`Deployed: Timelock, implementation | ${timelock.address} ${implementation}`);

    if (configType !== "fork") saveTempConstructor(implementation, {});
    saveConfig(config, configType);
}
