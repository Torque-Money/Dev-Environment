import "@nomiclabs/hardhat-waffle";
import dotenv from "dotenv";
dotenv.config();

// Fork from mainnet to local environment
const NETWORK_URL = "https://rpc.ftm.tools/";
const BLOCK_NUMBER = 24017532;

export default {
    solidity: {
        compilers: [{ version: "0.8.4", settings: { optimizer: { enabled: true, runs: 200 } } }],
    },
    networks: {
        hardhat: {
            forking: {
                url: NETWORK_URL,
                // blockNumber: BLOCK_NUMBER,
            },
        },
        fantom: {
            url: NETWORK_URL,
            accounts: [process.env.PRIVATE_KEY],
        },
    },
};
