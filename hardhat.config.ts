import "@nomiclabs/hardhat-waffle";
import dotenv from "dotenv";
import { task } from "hardhat/config";
dotenv.config();

// Change the time of the network
task("time", "Changes the time of the blockchain")
    .addParam("time", "The seconds forward to set the blockchain to")
    .setAction(async (args, hre) => {
        // Get the time to set the blockchain forward by in minutes
        const seconds = args.time * 60;
        await hre.network.provider.send("evm_increaseTime", [seconds]);
        await hre.network.provider.send("evm_mine");
    });

// Fork from mainnet to local environment
const NETWORK_URL = "https://rpc.ftm.tools/";

export default {
    solidity: {
        compilers: [{ version: "0.8.4", settings: { optimizer: { enabled: true, runs: 200 } } }],
    },
    networks: {
        hardhat: {
            forking: {
                url: NETWORK_URL,
            },
        },
        fantom: {
            url: NETWORK_URL,
            accounts: [process.env.PRIVATE_KEY],
        },
    },
};
