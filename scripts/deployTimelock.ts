import hre from "hardhat";
import config from "../config.json";
import fs from "fs";

export default async function main() {
    // Deploy the timelock
    const timelockConfig = {
        minDelay: 259200,
        proposers: [config.governanceAddress],
        executors: [hre.ethers.constants.AddressZero],
        taxPercentage: 5,
        taxCooldown: 2.628e6,
    };
    const Timelock = await hre.ethers.getContractFactory("Timelock");
    const timelock = await Timelock.deploy(...Object.values(timelockConfig));
    await timelock.deployed();

    console.log(`Deployed timelock to ${timelock.address}`);
    config.timelockAddress = timelock.address;

    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
