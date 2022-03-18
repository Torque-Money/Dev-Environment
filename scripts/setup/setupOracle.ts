import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../utils/config/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let oracle = await hre.ethers.getContractAt("OracleApproved", config.contracts.oracleAddress);

    await (await oracle.setPool(config.contracts.leveragePoolAddress)).wait();
    console.log("-- Set pool");

    const oracleApproved = config.tokens.approved.filter((approved) => approved.setup.oracle).map((approved) => approved.address);
    const priceFeeds = config.tokens.approved.filter((approved) => approved.setup.oracle).map((approved) => approved.setup.priceFeed);
    const correctDecimals = config.tokens.approved.filter((approved) => approved.setup.oracle).map((approved) => approved.decimals);
    const isApproved = Array(oracleApproved.length).fill(true);
    await (await oracle.setApprovedPriceFeed(oracleApproved, priceFeeds, correctDecimals, isApproved)).wait();
    console.log("-- Set approved price feed");

    console.log("Setup: Oracle");
}
