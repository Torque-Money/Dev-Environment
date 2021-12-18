import hre from "hardhat";
import config from "../config.json";
import fs from "fs";
import { getContractAddress } from "ethers/lib/utils";

async function main() {
    // Compile contracts
    await hre.run("compile");

    // Deploy and setup pool contract + find the margin address before deployment
    const signer = hre.ethers.provider.getSigner();
    const transactionCount = await signer.getTransactionCount();
    const preMarginAddress = getContractAddress({
        from: await signer.getAddress(),
        nonce: transactionCount + 2,
    });

    const poolConfig = {
        periodLength: 60 * 60,
        cooldownLength: 20 * 60,
        taxPercent: 2,
        marginAddress: preMarginAddress,
    };
    const Pool = await hre.ethers.getContractFactory("VPool");
    const pool = await Pool.deploy(...Object.values(poolConfig));
    await pool.deployed();
    console.log(`Value pool deployed to ${pool.address}`);
    config.poolAddress = pool.address;

    for (const approved of config.approved) {
        await pool.approveToken(approved.address);
    }
    console.log("Approved tokens for use with the pool");

    // Deploy and setup the oracle contract
    const oracleConfig = {
        decimals: (1e12).toString(),
    };
    const Oracle = await hre.ethers.getContractFactory("Oracle");
    const oracle = await Oracle.deploy(...Object.values(oracleConfig));
    await oracle.deployed();
    console.log(`Oracle deployed to ${oracle.address}`);
    config.oracleAddress = oracle.address;

    for (const address of config.routerAddresses) {
        await oracle.addRouter(address);
    }
    console.log("Added routers to Oracle");

    // Deploy and setup the margin contract
    const marginConfig = {
        oracle: oracle.address,
        pool: pool.address,
        minBorrowPeriod: 5 * 60,
        maxInterestPercent: 5,
        minMarginLevel: 5,
    };
    const Margin = await hre.ethers.getContractFactory("Margin");
    const margin = await Margin.deploy(...Object.values(marginConfig));
    await margin.deployed();
    console.log(`Margin deployed to ${margin.address}`);
    config.marginAddress = margin.address;

    // Add deployer as tax collector
    const ownerAddress = await hre.ethers.provider.getSigner().getAddress();
    await pool.setTaxAccount(ownerAddress);
    console.log(`Added ${ownerAddress} as pool tax account`);

    // Save the data to the config
    fs.writeFileSync("config.json", JSON.stringify(config));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
