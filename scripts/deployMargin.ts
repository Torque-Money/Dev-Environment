import hre from "hardhat";
import config from "../config.json";
import fs from "fs";

async function main() {
    await hre.run("compile");

    // Deploy and setup the margin contract
    const marginConfig = {
        oracle: config.oracleAddress,
        pool: config.poolAddress,
        minBorrowLength: 5 * 60,
        maxInterestPercent: 5,
        minMarginThreshold: 5,
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
