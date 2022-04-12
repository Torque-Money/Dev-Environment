import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";

import { HardhatUserConfig } from "hardhat/config";

require("dotenv").config();

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
