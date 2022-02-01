import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const constructorArgs = {
        minDelay: hre.ethers.BigNumber.from(259200),
        proposers: [signerAddress],
        executors: [hre.ethers.constants.AddressZero],
        taxPercentageNumerator: 5,
        taxPercentageDenominator: 100,
        taxCooldown: hre.ethers.BigNumber.from(10).pow(3).mul(2628),
    };

    const Timelock = await hre.ethers.getContractFactory("Timelock");
    const timelock = await Timelock.deploy(
        constructorArgs.taxPercentageDenominator,
        constructorArgs.taxPercentageDenominator,
        constructorArgs.taxCooldown,
        constructorArgs.minDelay,
        constructorArgs.proposers,
        constructorArgs.executors
    );
    await timelock.deployed();

    config.timelockAddress = timelock.address;
    console.log(`Deployed: Timelock | ${timelock.address}`);

    if (configType !== "fork") saveTempConstructor(timelock.address, constructorArgs);
    saveConfig(config, configType);
}
