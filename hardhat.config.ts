import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

import { HardhatUserConfig, task } from "hardhat/config";

require("dotenv").config();

task("sandbox", "Sandbox for interacting with blockchain", async (args, hre) => {
    const data = {
        VaultV1: {
            proxies: ["0x7b02CBA8c6bFAc6eBAb2dfA57096A9D60d2162Ae"],
            beacon: "0xAA6F01966f379dfCD7E8817F248643000b39f06D",
            implementation: "0x6b71f6e5C6b2FC1C0B3F52fD1b45D0FA724f35ea",
        },
        BeefyLPStrategy: {
            proxies: ["0x6Ad07E659563490d40377a98a7f0f62ed7d38C41"],
            beacon: "0xAcB597F234ECdb6E8E67773D1a9952877CDe708E",
            implementation: "0x87E995ee8fC7B92AE651169a62Be8986d71cC895",
        },
    };

    const vaultV1 = await hre.ethers.getContractAt("TorqueVaultV1", data.VaultV1.proxies[0]);
    const strategy = await hre.ethers.getContractAt("BeefyLPStrategy", data.BeefyLPStrategy.proxies[0]);

    console.log("Vault");
    console.log(await vaultV1.feePercent());
    console.log(await vaultV1.getStrategy());
    console.log(await vaultV1.tokenCount());

    console.log("\nStrategy");
    console.log(await strategy.APY());
    console.log(await strategy.uniRouter());
    console.log(await strategy.tokenCount());
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
