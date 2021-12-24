import hre from "hardhat";
import config from "../config.json";
import fs from "fs";

export default async function main() {
    // Deploy the yield approval

    // Using the formula yieldPercent < slashRate / (slashRate + time + offset)
    const percentAfterTimeframe = hre.ethers.BigNumber.from(10);
    const timeframe = hre.ethers.BigNumber.from(3.154e7);
    const slashingRate = percentAfterTimeframe.mul(timeframe).div(hre.ethers.BigNumber.from(100).sub(percentAfterTimeframe)); // slash < percentage * timeframe / (1 - percentage) (solve for p)

    const percentInitial = hre.ethers.BigNumber.from(60);
    const slashOffset = slashingRate.sub(percentInitial);

    const yieldApprovedConfig = {
        pool: config.poolAddress,
        margin: config.marginAddress,
        oracle: config.oracleAddress,
        token: config.tokenAddress,
        slashingRate: slashingRate,
        slashOffset: slashOffset,
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
