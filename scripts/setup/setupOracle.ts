import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType} from "../util/chooseConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const oracle = await hre.ethers.getContractAt("Oracle", config.oracleAddress);

    const oracleApproved = config.approved.map((approved) => approved.address);
    const priceFeeds = config.approved.map((approved) => approved.priceFeed);
    const reservePriceFeeds = config.approved.map((approved) => approved.reservePriceFeed);
    const correctDecimals = config.approved.map((approved) => approved.decimals);
    const oracleSupported = Array(oracleApproved.length).fill(true);
    await oracle.setPriceFeed(oracleApproved, priceFeeds, reservePriceFeeds, correctDecimals, oracleSupported);

    console.log("Setup: Oracle");
}
