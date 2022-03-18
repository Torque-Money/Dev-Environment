import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../utils/config/utilConfig";
import {getFilteredApproved, getFilteredTokens} from "../utils/tokens/utilGetTokens";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let oracle = await hre.ethers.getContractAt("OracleApproved", config.contracts.oracleAddress);

    await (await oracle.setPool(config.contracts.leveragePoolAddress)).wait();
    console.log("-- Set pool");

    const oracleApprovedConfig = getFilteredApproved(config, "oracle");
    const oracleApproved = oracleApprovedConfig.map((approved) => approved.address);
    const priceFeeds = oracleApprovedConfig.map((approved) => (approved.setup as any).priceFeed);
    const correctDecimals = oracleApprovedConfig.map((approved) => approved.decimals);
    const isApproved = Array(oracleApprovedConfig.length).fill(true);
    await (await oracle.setApprovedPriceFeed(oracleApproved, priceFeeds, correctDecimals, isApproved)).wait();
    console.log("-- Set approved price feed");

    console.log("Setup: Oracle");
}
