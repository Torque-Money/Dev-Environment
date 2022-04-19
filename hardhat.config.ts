import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

import { HardhatUserConfig, task } from "hardhat/config";

import { loadData } from "./src/scripts/utils/data";

require("dotenv").config();

task("sandbox", "Sandbox for interacting with blockchain", async (args, hre) => {
    const data = loadData();

    const vaultV1 = await hre.ethers.getContractAt("TorqueVaultV1", data.contracts.VaultV1.proxies[0]);
    const strategy = await hre.ethers.getContractAt("BeefyLPStrategy", data.contracts.BeefyLPStrategy.proxies[0]);

    console.log("Vault");
    console.log(await vaultV1.feePercent());
    console.log(await vaultV1.getStrategy());
    console.log(await vaultV1.tokenCount());

    console.log("\nStrategy");
    console.log(await strategy.APY());
    console.log(await strategy.uniRouter());
    console.log(await strategy.tokenCount());

    // **** Strategy
    // **** Assign the vault as a controller of the strategy
    // **** Assign the emergency to the timelock (and revoke)
    // **** Assign strategy admin to the timelock (and revoke)

    // **** Vault
    // **** Assign the fee to the timelock (and revoke)
    // **** Assign the emergency to the timelock (and revoke)
    // **** Assign the vault admin to the timelock (and revoke)
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
