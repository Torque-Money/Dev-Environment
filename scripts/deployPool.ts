import hre from "hardhat";
import config from "../config.json";
import fs from "fs";

export default async function main() {
    // Deploy the liquidity pool - this should be done before deploying any other contract, and needs to be deployed before the margin
    const poolConfig = {
        periodLength: 2.628e6, // 1 month
        cooldownLength: 86400, // 1 day
        taxPercent: 5, // 5%
    };
    const Pool = await hre.ethers.getContractFactory("LPool");
    const pool = await Pool.deploy(...Object.values(poolConfig));
    await pool.deployed();
    console.log(`Liquidity pool deployed to ${pool.address}`);
    config.poolAddress = pool.address;

    for (const approved of config.approved) {
        await pool.approveToken(approved.address);
    }
    console.log("Approved tokens for use with the pool");

    fs.writeFileSync("config.json", JSON.stringify(config));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
