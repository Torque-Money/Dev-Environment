import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

import { HardhatUserConfig, task } from "hardhat/config";

require("dotenv").config();

task("sandbox", "Sandbox for interacting with blockchain", async (args, hre) => {
    const data =  {
        VaultV1: {
            proxies: ["0x5FC8d32690cc91D4c39d9d3abcBD16989F875707"],
            beacon: "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
            implementation: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"
        },
        BeefyLPStrategy: {
            proxies: ["0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"],
            beacon: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
            implementation: "0x5FbDB2315678afecb367f032d93F642f64180aa3"
        }
    }

    const vaultV1 = await hre.ethers.getContractAt("TorqueVaultV1", data.VaultV1.proxies[0]);
    const strategy = await hre.ethers.getContractAt("BeefyLPStrategy", data.BeefyLPStrategy.proxies[0]);

    // **** Interact with the contracts and see if they work or not
});

export default {
    solidity: {
        compilers: [{ version: "0.8.10", settings: { optimizer: { enabled: true, runs: 200 } } }],
    },
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
    etherscan: {
        apiKey: {
            opera: process.env.API_KEY_OPERA,
        },
    },
} as HardhatUserConfig;
