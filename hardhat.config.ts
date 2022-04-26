import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

import { HardhatUserConfig, task } from "hardhat/config";

import { loadData } from "./scripts/utils";

require("dotenv").config();

task("sandbox", "Sandbox for interacting with blockchain", async (args, hre) => {
    const data = loadData();

    const vaultV1 = await hre.ethers.getContractAt("TorqueVaultV1", data.contracts.VaultV1.proxies[0]);
    const strategy = await hre.ethers.getContractAt("BeefyLPStrategy", data.contracts.BeefyLPStrategy.proxies[0]);

    const caller = await hre.ethers.provider.getSigner().getAddress();

    // === Strategy ===
    // Assign the vault as a controller of the strategy
    await (await strategy.grantRole(await strategy.STRATEGY_CONTROLLER_ROLE(), vaultV1.address)).wait();

    // Assign the emergency to the timelock (and revoke)
    const EMERGENCY_ADMIN_ROLE = await strategy.EMERGENCY_ADMIN_ROLE();
    await (await strategy.grantRole(EMERGENCY_ADMIN_ROLE, data.contracts.timelock)).wait();
    await (await strategy.renounceRole(EMERGENCY_ADMIN_ROLE, caller)).wait();

    // Assign strategy admin to the timelock (and revoke)
    const STRATEGY_ADMIN_ROLE = await strategy.STRATEGY_ADMIN_ROLE();
    await (await strategy.grantRole(STRATEGY_ADMIN_ROLE, data.contracts.timelock)).wait();
    await (await strategy.renounceRole(STRATEGY_ADMIN_ROLE, caller)).wait();

    // === Vault ===
    // Assign the fee to the timelock (and revoke)
    const FEE_ADMIN_ROLE = await vaultV1.FEE_ADMIN_ROLE();
    await (await vaultV1.grantRole(FEE_ADMIN_ROLE, data.contracts.timelock)).wait();
    await (await vaultV1.renounceRole(FEE_ADMIN_ROLE, caller)).wait();

    // Assign the emergency to the timelock (and revoke)
    await (await vaultV1.grantRole(EMERGENCY_ADMIN_ROLE, data.contracts.timelock)).wait();
    await (await vaultV1.renounceRole(EMERGENCY_ADMIN_ROLE, caller)).wait();

    // Assign the vault admin to the timelock (and revoke)
    const VAULT_ADMIN_ROLE = await vaultV1.VAULT_ADMIN_ROLE();
    await (await vaultV1.grantRole(VAULT_ADMIN_ROLE, data.contracts.timelock)).wait();
    await (await vaultV1.renounceRole(VAULT_ADMIN_ROLE, caller)).wait();
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
