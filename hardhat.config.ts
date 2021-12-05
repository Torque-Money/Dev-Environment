import "@nomiclabs/hardhat-waffle";

// Fork from mainnet to local environment
const NETWORK_URL = "https://rpc.ftm.tools/";
const BLOCK_NUMBER = 24017532;

export default {
    solidity: "0.8.4",
    networks: {
        hardhat: {
            forking: {
                url: NETWORK_URL,
                blockNUmber: BLOCK_NUMBER,
            },
        },
    },
};
