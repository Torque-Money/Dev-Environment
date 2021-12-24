import hre from "hardhat";
import config from "../config.json";
import fs from "fs";

export default async function main() {
    // Deploy and setup the margin contract
    const marginConfig = {
        oracle: config.oracleAddress,
        pool: config.poolAddress,
        minMarginThreshold: 5, // 5%
        minBorrowLength: 86400, // 1 day
        maxInterestPercent: 15, // 15%
    };
    const Margin = await hre.ethers.getContractFactory("Margin");
    const margin = await Margin.deploy(...Object.values(marginConfig));
    await margin.deployed();
    console.log(`Margin deployed to ${margin.address}`);
    config.marginAddress = margin.address;

    fs.writeFileSync("config.json", JSON.stringify(config));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
