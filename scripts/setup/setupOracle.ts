import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const oracle = await hre.ethers.getContractAt("Oracle", config.oracleAddress);

    const oracleApproved = config.approved.filter((approved) => approved.oracle).map((approved) => approved.address);
    const priceFeeds = config.approved.filter((approved) => approved.oracle).map((approved) => approved.priceFeed);
    const reservePriceFeeds = config.approved.filter((approved) => approved.oracle).map((approved) => approved.reservePriceFeed);
    const correctDecimals = config.approved.filter((approved) => approved.oracle).map((approved) => approved.decimals);
    const oracleSupported = Array(oracleApproved.length).fill(true);
    await oracle.setPriceFeed(oracleApproved, priceFeeds, reservePriceFeeds, correctDecimals, oracleSupported);

    console.log("Setup: Oracle");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
