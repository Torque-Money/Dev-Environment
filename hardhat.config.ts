import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";
import "@openzeppelin/hardhat-defender";

import {task} from "hardhat/config";

import dotenv from "dotenv";
dotenv.config();

import deploy from "./scripts/deploy/deploy";
import setup from "./scripts/setup/setup";

import {verifyAll} from "./scripts/utils/utilVerify";
import {testWrapper} from "./scripts/utils/test/utilTest";
import getConfigType from "./scripts/utils/config/utilConfigTypeSelector";

task("deploy", "Deploy contracts onto network", async (args, hre) => {
    await hre.run("compile");
    const configType = getConfigType(hre);

    await deploy(configType, hre);
    await setup(configType, hre);
});

task("verify-all", "Verify all contracts on block explorer", async (args, hre) => await verifyAll(hre));

task("test-functionality", "Run functionality tests", async (args, hre) => {
    const basePath = process.cwd() + "/test/functionality/";

    const files = ["1.functionTimelock.ts", "2.functionInterest.ts", "3.functionHandlePriceMovement.ts", "4.functionalFlashLend.ts"].map((file) => basePath + file);

    await testWrapper(hre, async () => await hre.run("test", {testFiles: files}));
});

task("test-interactions", "Run interaction tests", async (args, hre) => {
    const basePath = process.cwd() + "/test/interactions/";

    // **** I am going to seperate the margin long into functionality and the interactions

    const files = [
        // "1.interactPool.ts",
        // "2.interactOracle.ts",
        // "3.interactConverter.ts",
        "4.interactMarginLong.ts",
    ].map((file) => basePath + file);

    // await testWrapper(hre, async () => await hre.run("test", {testFiles: files}));
    await hre.run("test", {testFiles: files});
});

task("test-verify-deployment", "Run verification of deployed contracts tests", async (args, hre) => {
    const basePath = process.cwd() + "/test/verifyDeployed/";

    const files = [
        "1.verifyPool.ts",
        "2.verifyOracle.ts",
        "3.verifyTimelock.ts",
        "4.verifyConverter.ts",
        "5.verifyFlashLend.ts",
        "6.verifyResolver.ts",
        "7.verifyMarginLong.ts",
    ].map((file) => basePath + file);

    await hre.run("test", {testFiles: files});
});

const NETWORK_URL = process.env.NETWORK_URL;
const PINNED_BLOCK = 32177754;

const NETWORK_URL_TEST = process.env.NETWORK_URL_TEST;

export default {
    solidity: {
        compilers: [{version: "0.8.9", settings: {optimizer: {enabled: true, runs: 200}}}],
    },
    networks: {
        hardhat: {
            chainId: 1337,
            forking: {
                url: NETWORK_URL,
                blockNumber: PINNED_BLOCK,
            },
        },
        mainnet: {
            chainId: 250,
            url: NETWORK_URL,
            accounts: [process.env.PRIVATE_KEY],
        },
        testnet: {
            chainId: 4,
            url: NETWORK_URL_TEST,
            accounts: [process.env.PRIVATE_KEY],
        },
    },
    etherscan: {
        apiKey: {
            opera: process.env.FTMSCAN_API_KEY,
            rinkeby: process.env.ETHERSCAN_API_KEY,
        },
    },
    defender: {
        apiKey: process.env.OZ_API_KEY,
        apiSecret: process.env.OZ_API_SECRET,
    },
};
