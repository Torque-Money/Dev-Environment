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
        sources: "src/contracts",
        tests: "src/test/js",
    },
    networks: {
        // opera: {
        //     chainId: 250,
        //     url: process.env.NETWORK_URL_OPERA,
        //     accounts: [process.env.PRIVATE_KEY_OPERA],
        // },
    },
} as HardhatUserConfig;
