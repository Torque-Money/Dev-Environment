import hre from "hardhat";
import config from "../config.json";
import fs from "fs";

export default async function main() {
    // Deploy the yield approval
    const yieldApprovedConfig = {
        pool: config.poolAddress,
    };
    const YieldApproved = await hre.ethers.getContractFactory("YieldApproved");
    const yieldApproved = await YieldApproved.deploy(...Object.values(yieldApprovedConfig));
    await yieldApproved.deployed();

    console.log(`Deployed yield approved to ${yieldApproved.address}`);
    config.yieldApprovedAddress = yieldApproved.address;

    fs.writeFileSync("config.json", JSON.stringify(config));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
