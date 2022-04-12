import { task, HardhatUserConfig } from "hardhat/config";

require("dotenv").config();

task("renounce-timelock", "Renounce timelock admin privelidges", async (args, hre) => {});

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
