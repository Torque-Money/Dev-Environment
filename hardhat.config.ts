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
import utilUpdateFiles from "./scripts/utils/utilUpdateFiles";
import {verifyAll} from "./scripts/utils/utilVerify";
import {testWrapper} from "./scripts/utils/helpers/utilTest";

task("deploy-main", "Deploy contracts onto mainnet", async (args, hre) => {
    await hre.run("compile");

    await deploy("main", hre);
    await setup("main", hre);

    await utilUpdateFiles();
});

task("deploy-test", "Deploy contracts onto testnet", async (args, hre) => {
    await hre.run("compile");

    await deploy("test", hre);
    await setup("test", hre);

    await utilUpdateFiles();
});

task("deploy-fork", "Deploy contracts onto forked network", async (args, hre) => {
    await hre.run("compile");

    await deploy("fork", hre);
    await setup("fork", hre);

    await utilUpdateFiles();
});

task("update-files", "Update config files", async (args, hre) => await utilUpdateFiles());

task("verify-all", "Verify all contracts on block explorer", async (args, hre) => {
    await verifyAll(hre);
});

task("test-functionality", "Run functionality tests", async (args, hre) => {
    const basePath = process.cwd() + "/test/functionality/";

    const files = [
        "1.testPool.ts",
        "2.testOracle.ts",
        "3.testTimelock.ts",
        "4.testConverter.ts",
        "5.testFlashLend.ts",
        "6.testMarginLong.ts",
        "7.testInterest.ts",
        "8.testHandlePriceMovement.ts",
    ].map((file) => basePath + file);

    await testWrapper(hre, async () => await hre.run("test", {testFiles: files}));
});

task("test-verification", "Run verification tests");

const NETWORK_URL = "https://rpc.ftm.tools/";
const PINNED_BLOCK = 32177754;

const NETWORK_URL_TEST = process.env.NETWORK_URL;

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
