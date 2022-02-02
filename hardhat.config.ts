import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

import {task} from "hardhat/config";

import dotenv from "dotenv";
dotenv.config();

import deploy from "./scripts/deploy/deploy";
import setup from "./scripts/setup/setup";

import utilFund from "./scripts/util/utilFund";
import utilApprove from "./scripts/util/utilApprove";
import utilUpdateFiles from "./scripts/util/utilUpdateFiles";

import {verifyAll} from "./scripts/util/utilVerify";
import {chooseConfig} from "./scripts/util/utilConfig";

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

    await utilFund("fork", hre);
    await utilApprove("fork", hre);

    await utilUpdateFiles();
});

task("verify-all", "Verify all contracts on block explorer", async (args, hre) => {
    await verifyAll(hre);
});

task("sandbox", "Sandbox test", async (args, hre) => {
    const config = chooseConfig("test");

    const pool = await hre.ethers.getContractAt("LPool", config.leveragePoolAddress);

    console.log(await pool.isPT(config.approved[0].address));
});

const NETWORK_URL = "https://rpc.ftm.tools/";
const PINNED_BLOCK = 28793946;
const NETWORK_URL_TEST = process.env.NETWORK_URL;

export default {
    solidity: {
        compilers: [{version: "0.8.9", settings: {optimizer: {enabled: true, runs: 200}}}],
    },
    networks: {
        hardhat: {
            forking: {
                url: NETWORK_URL,
                blockNumber: PINNED_BLOCK,
            },
        },
        mainnet: {
            url: NETWORK_URL,
            accounts: [process.env.PRIVATE_KEY],
        },
        testnet: {
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
};
