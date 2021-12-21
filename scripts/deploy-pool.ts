import hre from "hardhat";
import config from "../config.json";
import fs from "fs";
import getFutureAddress from "../utils/getFutureAddress";

async function main() {
    await hre.run("compile");

    const signer = hre.ethers.provider.getSigner();
    const preMarginAddress = await getFutureAddress(signer, 2);

    const poolConfig = {
        periodLength: 60 * 60,
        cooldownLength: 20 * 60,
        taxPercent: 2,
        marginAddress: preMarginAddress,
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
