import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../utils/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    if (config.contracts.multisig) {
        const signer = await hre.ethers.provider.getSigner().getAddress();

        const timelock = await hre.ethers.getContractAt("Timelock", config.contracts.timelockAddress);

        const TIMELOCK_ADMIN = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TIMELOCK_ADMIN_ROLE"));
        const TIMELOCK_PROPOSER = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("PROPOSER_ROLE"));
        await (await timelock.grantRole(TIMELOCK_ADMIN, config.contracts.multisig)).wait();
        console.log("-- Granted multisig admin");
        await (await timelock.grantRole(TIMELOCK_PROPOSER, config.contracts.multisig)).wait();
        console.log("-- Granted multisig proposer");
        await (await timelock.renounceRole(TIMELOCK_PROPOSER, signer)).wait();
        console.log("-- Renounced multisig proposer");
        await (await timelock.renounceRole(TIMELOCK_ADMIN, signer)).wait();
        console.log("-- Renounced multisig admin");
    }

    console.log("Setup: Multisig");
}
