import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";

import {task} from "hardhat/config";

import deploy from "./scripts/deploy/deploy";
import setup from "./scripts/setup/setup";

import utilFund from "./scripts/util/utilFund";
import utilApprove from "./scripts/util/utilApprove";
import utilUpdateFiles from "./scripts/util/utilUpdateFiles";

import dotenv from "dotenv";
import {verifyAll} from "./scripts/util/utilVerify";
dotenv.config();

task("deploy-main", "Deploy contracts onto mainnet", async (args, hre) => {
    hre.run("compile");

    await deploy("main", hre);
    await setup("main", hre);

    await utilUpdateFiles();
});

task("deploy-test", "Deploy contracts onto testnet", async (args, hre) => {
    hre.run("compile");

    await deploy("test", hre);
    await setup("test", hre);

    await utilUpdateFiles();
});

task("deploy-fork", "Deploy contracts onto forked network", async (args, hre) => {
    hre.run("compile");

    await deploy("fork", hre);
    await setup("fork", hre);

    await utilFund("fork", hre);
    await utilApprove("fork", hre);

    await utilUpdateFiles();
});

task("verify-all", "Verify all contracts on block explorer", async (args, hre) => {
    await verifyAll(hre);
});

task("sandbox", "A sandbox for testing", async (args, hre) => {
    console.log("Sandbox");
});

const NETWORK_URL = "https://rpc.ftm.tools/";
const NETWORK_URL_TEST = process.env.NETWORK_URL;

export default {
    solidity: {
        compilers: [{version: "0.8.9", settings: {optimizer: {enabled: true, runs: 200}}}],
    },
    networks: {
        hardhat: {
            forking: {
                url: NETWORK_URL,
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
