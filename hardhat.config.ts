import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

import { HardhatUserConfig, task } from "hardhat/config";

require("dotenv").config();

task("fee", "Assign fee to multisig", async (args, hre) => {
    const vault = await hre.ethers.getContractAt("Vault", "0x242E9E75Dea7Fd2Ba2e55783B79E76648178145D");
    const multisig = "0x3FAe01d46ebe019b14216D17E3947871daa2F58b";

    await (await vault.setFeeRecipient(multisig)).wait();
    console.log("Updated the fee");

    console.log(await vault.feeRecipient());
});

export default {
    solidity: {
        compilers: [{ version: "0.8.10", settings: { optimizer: { enabled: true, runs: 200 } } }],
    },
    paths: {
        sources: "src",
        tests: "test/js",
    },
    networks: {
        hardhat: {
            forking: {
                url: process.env.NETWORK_URL_OPERA,
            },
            accounts: [{ privateKey: process.env.PRIVATE_KEY_OPERA, balance: "1000000000000000000000" }],
        },
        opera: {
            url: process.env.NETWORK_URL_OPERA,
            accounts: [process.env.PRIVATE_KEY_OPERA],
        },
    },
    etherscan: {
        apiKey: {
            opera: process.env.API_KEY_OPERA,
        },
    },
} as HardhatUserConfig;
