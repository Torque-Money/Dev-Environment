import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

import { HardhatUserConfig, task } from "hardhat/config";

require("dotenv").config();

import { loadData } from "./scripts/utils";

task("t-deploy", "Check if the verify is really broken or not", async (args, hre) => {
    const Vault = await hre.ethers.getContractFactory("Vault");
    const vault = await Vault.deploy();
    await vault.deployed();

    console.log(vault.address);
});

task("upgradeable", "Check if a contract can be upgraded", async (args, hre) => {
    const data = loadData();

    const Vault = await hre.ethers.getContractFactory("Vault");
    const x = await hre.upgrades.prepareUpgrade(data.contracts["VaultV2.0"].beacon, Vault);
    console.log(x);
});

export default {
    solidity: {
        compilers: [{ version: "0.8.10", settings: { optimizer: { enabled: true, runs: 200 } } }],
    },
    paths: {
        sources: "src",
        tests: "test/js",
    },
    networks: {
        hardhat: {
            forking: {
                url: process.env.NETWORK_URL_OPERA,
            },
            accounts: [{privateKey: process.env.PRIVATE_KEY_OPERA, balance: "1000000000000000000000"}],
        },
        opera: {
            url: process.env.NETWORK_URL_OPERA,
            accounts: [process.env.PRIVATE_KEY_OPERA],
        },
    },
    etherscan: {
        apiKey: {
            opera: process.env.API_KEY_OPERA,
        },
    },
} as HardhatUserConfig;
