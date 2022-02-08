import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const constructorArgs = {
        minDelay: hre.ethers.BigNumber.from(86400).mul(3),
        proposers: [signerAddress],
        executors: [hre.ethers.constants.AddressZero],
        taxPercentageNumerator: 10,
        taxPercentageDenominator: 100,
        taxCooldown: hre.ethers.BigNumber.from(86400).mul(30),
    };

    const Timelock = await hre.ethers.getContractFactory("Timelock");
    const timelock = await Timelock.deploy(
        constructorArgs.minDelay,
        constructorArgs.proposers,
        constructorArgs.executors,
        constructorArgs.taxPercentageNumerator,
        constructorArgs.taxPercentageDenominator,
        constructorArgs.taxCooldown
    );
    await timelock.deployed();

    config.timelockAddress = timelock.address;
    console.log(`Deployed: Timelock | ${timelock.address}`);

    if (configType !== "fork") saveTempConstructor(timelock.address, constructorArgs);
    saveConfig(config, configType);
}
