import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

import { HardhatUserConfig, task } from "hardhat/config";

import { loadData } from "./scripts/utils";

require("dotenv").config();

task("Helper", "Helper task", async (args, hre) => {
    const data = loadData();
    
    const vault = await hre.ethers.getContractAt("Vault", data.contracts.VaultV1.proxies[0]);

    const VAULT_CONTROLLER_ROLE = await vault.VAULT_CONTROLLER_ROLE();
    console.log("Vault controller role", VAULT_CONTROLLER_ROLE)
    const VAULT_ADMIN_ROLE = await vault.VAULT_ADMIN_ROLE();
    console.log("Vault admin role", VAULT_ADMIN_ROLE)

    const encoded = vault.interface.encodeFunctionData("grantRole", [VAULT_CONTROLLER_ROLE, data.contracts.LensV1.proxies[0]]);
    console.log("Encoded grant role", encoded);

    console.log("Hash zero", hre.ethers.constants.HashZero);
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
