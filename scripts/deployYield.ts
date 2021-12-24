import hre from "hardhat";
import config from "../config.json";
import fs from "fs";

export default async function main() {
    // Deploy the yield approval

    // Using the formula yieldPercent < slashRate / (slashRate + time + offset), then solve simultaneously for yield = p_f at time = t and yield = p_0 at time = 0
    const percentInitial = hre.ethers.BigNumber.from(40);
    const percentFinal = hre.ethers.BigNumber.from(1);
    const timeframe = hre.ethers.BigNumber.from(6.307e7); // 2 years

    const slashRate = percentInitial.mul(percentFinal).mul(timeframe).div(percentInitial.sub(percentFinal)).div(100);
    const slashOffset = slashRate.mul(hre.ethers.BigNumber.from(100).sub(percentInitial)).div(percentInitial);

    const yieldApprovedConfig = {
        pool: config.poolAddress,
        margin: config.marginAddress,
        oracle: config.oracleAddress,
        token: config.tokenAddress,
        slashingRate: slashRate,
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
