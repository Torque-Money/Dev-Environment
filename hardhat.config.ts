import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

import { HardhatUserConfig } from "hardhat/config";

require("dotenv").config();

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
            // accounts: [process.env.PRIVATE_KEY_OPERA],
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
