/**
 * @type import('hardhat/config').HardhatUserConfig
 */

import { task, HardhatUserConfig } from "hardhat/config";

require("dotenv").config();

export default {
    solidity: "0.8.10",
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
