import hre from "hardhat";
import fs from "fs";
import config from "../../config.json";

export default async function main() {
    const constructorArgs = {
        pool: config.leveragePoolAddress,
        oracle: config.oracleAddress,
        minMarginLevelPercentNumerator: 105,
        minMarginLevelPercentDenominator: 100,
        minCollateralPrice: hre.ethers.BigNumber.from(10).pow(18).mul(100),
        maxLeverage: 125,
        liquidationFeePercentNumerator: 10,
        liquidationFeePercentDenominator: 100,
    };
    const MarginLong = await hre.ethers.getContractFactory("MarginLong");
    const marginLong = await MarginLong.deploy(...Object.values(constructorArgs));
    config.marginLongAddress = marginLong.address;
    console.log("Deployed: Margin long");

    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
