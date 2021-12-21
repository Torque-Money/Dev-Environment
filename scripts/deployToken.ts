import hre from "hardhat";
import fs from "fs";
import config from "../config.json";

async function main() {
    await hre.run("compile");

    // Deploy the token
    const tokenConfig = {
        tokenAmount: hre.ethers.BigNumber.from(10).pow(18).mul(1000),
        yieldSlashRate: 10000,
        yieldReward: hre.ethers.BigNumber.from(10).pow(18).mul(5),
        yieldApproval: config.yieldApprovedAddress,
    };
    const Token = await hre.ethers.getContractFactory("Token");
    const token = await Token.deploy(...Object.values(tokenConfig));
    await token.deployed();

    console.log(`Deployed token to ${token.address}`);
    config.tokenAddress = token.address;

    fs.writeFileSync("config.json", JSON.stringify(config));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
