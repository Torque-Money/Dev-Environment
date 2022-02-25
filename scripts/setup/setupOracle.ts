import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../utils/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let oracle = await hre.ethers.getContractAt("OracleApproved", config.contracts.oracleAddress);

    const oracleApproved = config.tokens.approved.filter((approved) => approved.oracle).map((approved) => approved.address);
    const priceFeeds = config.tokens.approved.filter((approved) => approved.oracle).map((approved) => approved.priceFeed);
    const correctDecimals = config.tokens.approved.filter((approved) => approved.oracle).map((approved) => approved.decimals);
    const isApproved = Array(oracleApproved.length).fill(true);
    await (await oracle.setApprovedPriceFeed(oracleApproved, priceFeeds, correctDecimals, isApproved)).wait();

    console.log("Setup: Oracle");
}
