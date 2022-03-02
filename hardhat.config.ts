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
import getConfigType from "./scripts/utils/utilConfigTypeSelector";

task("deploy", "Deploy contracts onto network", async (args, hre) => {
    await hre.run("compile");
    const configType = await getConfigType(hre);

    await deploy(configType, hre);
    await setup(configType, hre);

    await utilUpdateFiles();
});

task("update-files", "Update config files", async (args, hre) => await utilUpdateFiles());

task("verify-all", "Verify all contracts on block explorer", async (args, hre) => await verifyAll(hre));

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

task("test-verification", "Run verification tests"); // This will be similar to the functionality tests ^ except will be used to verify the deployment was successful

// **** But now I have a problem where I need to override the normal selected network config with the config I wish to use (mostly just applies to functionality - potential override here ?)

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
