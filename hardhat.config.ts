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

import configTest from "./config.test.json";
import ERC20Abi from "@openzeppelin/contracts/build/contracts/ERC20.json";
import UniswapV2Router02Abi from "./artifacts/contracts/lib/UniswapV2Router02.sol/UniswapV2Router02.json";
import {ERC20, UniswapV2Router02} from "./typechain-types";

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
    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const router = new hre.ethers.Contract(configTest.routerAddress, UniswapV2Router02Abi.abi, signer) as UniswapV2Router02;

    const inToken = "0x01BE23585060835E02B77ef475b0Cc51aA1e0709"; // Link
    const inAmount = hre.ethers.BigNumber.from(10).pow(18).mul(10);

    const token = new hre.ethers.Contract(inToken, ERC20Abi.abi, signer) as ERC20;

    await token.approve(configTest.routerAddress, inAmount);
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
