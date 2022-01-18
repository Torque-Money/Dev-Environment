import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";

import {task} from "hardhat/config";

import deploy from "./scripts/deploy/deploy";
import setup from "./scripts/setup/setup";

import utilFund from "./scripts/util/utilFund";
import utilApprove from "./scripts/util/utilApprove";
import utilUpdateFiles from "./scripts/util/utilUpdateFiles";

import dotenv from "dotenv";
dotenv.config();

task("deploy-main", "Deploy contracts onto mainnet", async (args, hre) => {
    await deploy(false, hre);
    await setup(false, hre);
});

task("deploy-test", "Deploy contracts onto testnet", async (args, hre) => {
    await deploy(true, hre);
    await setup(true, hre);
});

task("deploy-fork", "Deploy contracts onto forked network", async (args, hre) => {
    await deploy(false, hre);
    await setup(false, hre);

    await utilFund(hre);
    await utilApprove(hre);
    await utilUpdateFiles();
});

const NETWORK_URL = "https://rpc.ftm.tools/";
const NETWORK_URL_TEST = process.env.NETWORK_URL; // Rinkeby

export default {
    solidity: {
        compilers: [{version: "0.8.4", settings: {optimizer: {enabled: true, runs: 200}}}],
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
};
