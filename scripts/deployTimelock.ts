import hre from "hardhat";
import config from "../config.json";
import fs from "fs";

export default async function main() {
    await hre.run("compile");

    // Deploy the timelock
    const timelockConfig = {
        minDelay: 1,
        proposers: [config.daoAddress],
        executors: [config.daoAddress],
    };
    const Timelock = await hre.ethers.getContractFactory("TimelockController");
    const timelock = await Timelock.deploy(...Object.values(timelockConfig));
    await timelock.deployed();

    console.log(`Deployed timelock to ${timelock.address}`);
    config.timelockAddress = timelock.address;

    fs.writeFileSync("config.json", JSON.stringify(config));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
