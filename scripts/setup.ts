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
    const flashSwapDefault = await hre.ethers.getContractAt("FlashSwapDefault", config.flashSwapDefaultAddress);
    const isolatedMargin = await hre.ethers.getContractAt("IsolatedMargin", config.isolatedMarginAddress);
    const token = await hre.ethers.getContractAt("Token", config.tokenAddress);
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
    console.log("Setup pool: Finished setting tokens up");

    await pool.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_APPROVED_ROLE")), isolatedMargin.address);
    await pool.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN_ROLE")), timelock.address);
    await pool.setTaxAccount(timelock.address);
    await pool.renounceRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN_ROLE")), signerAddress);
    console.log("Setup pool: Finishing assigning roles");

    // ======== Setup the oracle ========
    const priceFeeds = config.approved.map((approved) => approved.priceFeed);
    const reservePriceFeeds = config.approved.map((approved) => approved.reservePriceFeed);
    const correctDecimals = config.approved.map((approved) => approved.decimals);
    const supported = Array(approvedTokens.length).fill(true);
    await oracle.setPriceFeed(approvedTokens, priceFeeds, reservePriceFeeds, correctDecimals, supported);
    await oracle.setDefaultStablecoin(approvedTokens[0]);
    console.log("Setup oracle: Finished adding supported tokens");

    await oracle.transferOwnership(timelock.address);
    console.log("Setup oracle: Finished transferring ownership");

    // ======== Setup the flash swap default ========
    await flashSwapDefault.transferOwnership(timelock.address);
    console.log("Setup flash swap default: Finished transferring ownership");

    // ======== Setup the isolated margin ========
    await isolatedMargin.approve(approvedTokens, supported);
    console.log("Setup isolated margin: Finished approving collateral tokens");

    await isolatedMargin.transferOwnership(timelock.address);
    console.log("Setup isolated margin: Finished transferring ownership");

    // ======== Setup the token ========
    await token.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TOKEN_ADMIN_ROLE")), timelock.address);
    await token.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TOKEN_MINTER_ROLE")), _yield.address);
    await token.renounceRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TOKEN_ADMIN_ROLE")), signerAddress);
    console.log("Setup token: Finishing assigning roles");

    // ======== Setup the timelock ========
    await timelock.renounceRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TIMELOCK_ADMIN_ROLE")), signerAddress);
    console.log("Setup timelock: Finishing assigning roles");

    // ======== Setup the yield ========
    const lpTokens = await Promise.all(approvedTokens.map((approved) => pool.LPFromPA(approved)));
    const rateNumerators = Array(lpTokens.length).fill(10);
    const rateDenominators = Array(lpTokens.length).fill(100);
    await _yield.setRates(lpTokens, rateNumerators, rateDenominators);
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
