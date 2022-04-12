import "@nomiclabs/hardhat-ethers";

import { task, HardhatUserConfig } from "hardhat/config";

require("dotenv").config();

import TimelockABI from "@openzeppelin/contracts-upgradeable/build/contracts/TimelockControllerUpgradeable.json";

task("renounce-timelock", "Renounce timelock admin privileges", async (args, hre) => {
    const TIMELOCK_ADDRESS = "0xF3C18b768Ca36c02564819a224a95E7a2EAc6239";
    const ADMIN_ROLE = "0x5f58e3a2316349923ce3780f8d587db2d72378aed66a8261c916544fa6846ca5";
    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    const timelock = await hre.ethers.getContractAt(TimelockABI.abi, TIMELOCK_ADDRESS);

    console.log(timelock);

    // await (await timelock.renounceRole(ADMIN_ROLE, signerAddress)).wait();
});

export default {
    paths: {
        sources: "src/contracts",
        tests: "src/test/js",
    },
    networks: {
        opera: {
            chainId: 250,
            url: process.env.NETWORK_URL_OPERA,
            accounts: [process.env.PRIVATE_KEY_OPERA],
        },
    },
} as HardhatUserConfig;
