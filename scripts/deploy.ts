import hre from "hardhat";
import config from "../config.json";
import fs from "fs";

async function main() {
    // Compile contracts
    await hre.run("compile");

    // Deploy and setup pool contract
    const poolConfig = {
        periodLength: 60 * 60,
        cooldownLength: 20 * 60,
        restakeReward: 1,
    };
    const Pool = await hre.ethers.getContractFactory("VPool");
    const pool = await Pool.deploy(...Object.values(poolConfig));
    await pool.deployed();

    console.log(`Pool deployed to ${pool.address}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
