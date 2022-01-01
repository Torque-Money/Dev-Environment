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

    const pool = await hre.ethers.getContractAt("LPool", config.poolAddress);
    const oracle = await hre.ethers.getContractAt("Oracle", config.oracleAddress);
    const flashSwap = await hre.ethers.getContractAt("FlashSwap", config.flashSwapAddress);
    const flashSwapDefault = await hre.ethers.getContractAt("FlashSwapDefault", config.flashSwapDefaultAddress);
    const isolatedMargin = await hre.ethers.getContractAt("IsolatedMargin", config.isolatedMarginAddress);
    const token = await hre.ethers.getContractAt("Token", config.tokenAddress);
    const governor = await hre.ethers.getContractAt("Governor", config.governorAddress);
    const timelock = await hre.ethers.getContractAt("Timelock", config.timelockAddress);
    const _yield = await hre.ethers.getContractAt("Yield", config.yieldAddress);

    // ======== Setup the pool ========
    const approvedTokens = config.approved.map((approved) => approved.address);
    const approvedNames = config.approved.map((approved) => "Torque Market Neutral " + approved.name);
    const approvedSymbols = config.approved.map((approved) => "tmn" + approved.symbol);
    await pool.approve(approvedTokens, approvedNames, approvedSymbols);
    const maxInterestMinNumerator = Array(approvedTokens.length).fill(15);
    const maxInterestMinDenominator = Array(approvedTokens.length).fill(100);
    await pool.setMaxInterestMin(approvedTokens, maxInterestMinNumerator, maxInterestMinDenominator);
    const maxInterestMaxNumerator = Array(approvedTokens.length).fill(45);
    const maxInterestMaxDenominator = Array(approvedTokens.length).fill(100);
    await pool.setMaxInterestMax(approvedTokens, maxInterestMaxNumerator, maxInterestMaxDenominator);
    const maxUtilizationNumerator = Array(approvedTokens.length).fill(60);
    const maxUtilizationDenominator = Array(approvedTokens.length).fill(100);
    await pool.setMaxUtilization(approvedTokens, maxUtilizationNumerator, maxUtilizationDenominator);

    // ======== Setup the oracle ========

    // Remove ownership of the contracts
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
