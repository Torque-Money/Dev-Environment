import {HardhatRuntimeEnvironment} from "hardhat/types";
import {OracleTest} from "../../typechain-types";
import {chooseConfig, ConfigType} from "../util/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    let oracle;
    if (configType === "main") oracle = await hre.ethers.getContractAt("Oracle", config.oracleAddress);
    else oracle = await hre.ethers.getContractAt("OracleTest", config.oracleAddress);

    const oracleApproved = config.approved.filter((approved) => approved.oracle).map((approved) => approved.address);
    const priceFeeds = config.approved.filter((approved) => approved.oracle).map((approved) => approved.priceFeed);
    const reservePriceFeeds = config.approved.filter((approved) => approved.oracle).map((approved) => approved.reservePriceFeed);
    const correctDecimals = config.approved.filter((approved) => approved.oracle).map((approved) => approved.decimals);
    const oracleSupported = Array(oracleApproved.length).fill(true);
    await oracle.setPriceFeed(oracleApproved, priceFeeds, reservePriceFeeds, correctDecimals, oracleSupported);

    const priceDecimals = await oracle.priceDecimals();
    if (configType === "fork") {
        oracle = oracle as OracleTest;
        await oracle.setPrice(config.approved[0].address, hre.ethers.BigNumber.from(10).pow(priceDecimals).mul(1));
        await oracle.setPrice(config.approved[1].address, hre.ethers.BigNumber.from(10).pow(priceDecimals).mul(30));
    } else if (configType === "test") {
        oracle = oracle as OracleTest;
        await oracle.setPrice(config.approved[0].address, hre.ethers.BigNumber.from(10).pow(priceDecimals).mul(1));
        await oracle.setPrice(config.approved[1].address, hre.ethers.BigNumber.from(10).pow(priceDecimals).mul(2000));
    }

    console.log("Setup: Oracle");
}
