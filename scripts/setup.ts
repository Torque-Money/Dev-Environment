import hre from "hardhat";
import fs from "fs";
import config from "../config.json";

import deployPool from "./deployPool";
import deployOracle from "./deployOracle";
import deployFlashSwap from "./deployFlashSwap";
import deployIsolatedMargin from "./deployIsolatedMargin";
import deployGovernance from "./deployGovernance";
import deployYield from "./deployYield";

export default async function main() {
    // Deploy contracts
    await deployPool();
    await deployOracle();
    await deployFlashSwap();
    await deployIsolatedMargin();
    await deployGovernance();
    await deployYield();

    // Get the deployer contracts
    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const pool = hre.ethers.getContractAt("LPool", config.poolAddress);
    const oracle = hre.ethers.getContractAt("Oracle", config.oracleAddress);
    const flashSwap = hre.ethers.getContractAt("FlashSwap", config.flashSwapAddress);
    const flashSwapDefault = hre.ethers.getContractAt("FlashSwapDefault", config.flashSwapDefaultAddress);
    const isolatedMargin = hre.ethers.getContractAt("IsolatedMargin", config.isolatedMarginAddress);
    const token = hre.ethers.getContractAt("Token", config.tokenAddress);
    const governor = hre.ethers.getContractAt("Governor", config.governorAddress);
    const timelock = hre.ethers.getContractAt("Timelock", config.timelockAddress);
    const _yield = hre.ethers.getContractAt("Yield", config.yieldAddress);

    // Approve tokens for use with the contracts

    // Remove ownership of the contracts
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
