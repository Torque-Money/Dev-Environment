import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../utils/utilConfig";
import {saveTempConstructor} from "../utils/utilVerify";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const constructorArgs = {
        minDelay: hre.ethers.BigNumber.from(64800),
        proposers: [signerAddress],
        executors: [hre.ethers.constants.AddressZero],
    };

    const Timelock = await hre.ethers.getContractFactory("Timelock");
    const timelock = await hre.upgrades.deployProxy(Timelock, Object.values(constructorArgs));
    await timelock.deployed();

    config.timelockAddress = timelock.address;
    config.timelockLogicAddress = await getImplementationAddress(hre.ethers.provider, timelock.address);
    console.log(`Deployed: Timelock proxy and timelock | ${timelock.address} ${config.timelockAddress}`);

    if (configType !== "fork") saveTempConstructor(timelock.address, {});
    saveConfig(config, configType);
}
