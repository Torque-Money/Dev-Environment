import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

import {task} from "hardhat/config";

import dotenv from "dotenv";
dotenv.config();

// import deploy from "./scripts/deploy/deploy";
// import setup from "./scripts/setup/setup";

// import utilFund from "./scripts/utils/utilFund";
// import utilApprove from "./scripts/utils/utilApprove";
// import utilUpdateFiles from "./scripts/utils/utilUpdateFiles";

// import {verifyAll} from "./scripts/utils/utilVerify";

// import {chooseConfig} from "./scripts/utils/utilConfig";

// task("deploy-main", "Deploy contracts onto mainnet", async (args, hre) => {
//     await hre.run("compile");

//     await deploy("main", hre);
//     await setup("main", hre);

//     await utilUpdateFiles();
// });

// task("deploy-test", "Deploy contracts onto testnet", async (args, hre) => {
//     await hre.run("compile");

//     await deploy("test", hre);
//     await setup("test", hre);

//     await utilUpdateFiles();
// });

// task("deploy-fork", "Deploy contracts onto forked network", async (args, hre) => {
//     await hre.run("compile");

//     await deploy("fork", hre);
//     await setup("fork", hre);

//     await utilFund("fork", hre);
//     await utilApprove("fork", hre);

//     await utilUpdateFiles();
// });

// task("verify-all", "Verify all contracts on block explorer", async (args, hre) => {
//     await verifyAll(hre);
// });

// task("sandbox", "Sandbox test", async (args, hre) => {
//     const config = chooseConfig("main");

//     const marginLong = await hre.ethers.getContractAt("MarginLong", config.marginLongAddress);

//     const BTC = "0x321162Cd933E2Be498Cd2267a90534A804051b11";
//     const account = "0x2eF15adAFA815Ca7A5ef307FC915EC0006EA64C7";

//     const isBorrowedToken = await marginLong.isBorrowedToken(BTC);
//     console.log(isBorrowedToken);

//     const isBorrowing = await marginLong["isBorrowing(address,address)"](BTC, account);
//     console.log(isBorrowing);
// });

const NETWORK_URL = "https://rpc.ftm.tools/";
const PINNED_BLOCK = 28793946;

const NETWORK_URL_TEST = process.env.NETWORK_URL;

export default {
    solidity: {
        compilers: [{version: "0.8.9", settings: {optimizer: {enabled: true, runs: 200}}}],
    },
    networks: {
        // hardhat: {
        //     chainId: 1337,
        //     forking: {
        //         url: NETWORK_URL,
        //         blockNumber: PINNED_BLOCK,
        //     },
        // },
        // mainnet: {
        //     chainId: 250,
        //     url: NETWORK_URL,
        //     accounts: [process.env.PRIVATE_KEY],
        // },
        // testnet: {
        //     chainId: 4,
        //     url: NETWORK_URL_TEST,
        //     accounts: [process.env.PRIVATE_KEY],
        // },
    },
    etherscan: {
        apiKey: {
            opera: process.env.FTMSCAN_API_KEY,
            rinkeby: process.env.ETHERSCAN_API_KEY,
        },
    },
};
