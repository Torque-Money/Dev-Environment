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

import utilFund from "./scripts/utils/utilFund";
import utilApprove from "./scripts/utils/utilApprove";
import utilClump from "./scripts/utils/utilClump";

import {verifyAll} from "./scripts/utils/utilVerify";
import {chooseConfig} from "./scripts/utils/utilConfig";

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

task("verify-all", "Verify all contracts on block explorer", async (args, hre) => {
    await verifyAll(hre);
});

task("test-wrapper", "Wrapper for tests", async (args, hre) => {
    await utilFund("fork", hre);
    await utilApprove("fork", hre);

    await hre.run("test");

    await utilClump("fork", hre);
});

task("sandbox", "Testing sandbox", async (args, hre) => {
    const config = chooseConfig("test");

    const accountToInpersonate = "0xa02E9e63A828a08f29eb75b1bBc0A9aFe7A97EfA";
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [accountToInpersonate],
    });
    const signer = await hre.ethers.getSigner(accountToInpersonate);
    console.log("Impersonated account");

    const marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress, signer);
    const tokenAddress = "0x01be23585060835e02b77ef475b0cc51aa1e0709";

    console.log("Awaiting result");
    await (await marginLong["repayAccount(address)"](tokenAddress)).wait();
    console.log("Finished");
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
            chainId: 1337,
            forking: {
                // url: NETWORK_URL,
                url: NETWORK_URL_TEST, // **** Remove
                // blockNumber: PINNED_BLOCK,
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
