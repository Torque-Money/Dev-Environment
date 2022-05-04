import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

import { HardhatUserConfig, task } from "hardhat/config";

require("dotenv").config();

task("Lol", "Lol", async (args, hre) => {
    console.log(await hre.ethers.provider.getSigner().getAddress());
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
                blockNumber: 32177754,
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
