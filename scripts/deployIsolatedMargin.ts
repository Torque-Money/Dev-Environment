import hre from "hardhat";
import fs from "fs";
import config from "../config.json";

export default async function main() {
    const constructorArgs = {
        pool: config.leveragePoolAddress,
        oracle: config.oracleAddress,
        flashSwap: config.flashSwapAddress,
        swapToleranceNumerator: 3,
        swapToleranceDenominator: 200,
        minMarginLevelNumerator: 105,
        minMarginLevelDenominator: 100,
        minCollateral: hre.ethers.BigNumber.from(100).mul(10).pow(18),
        liquidationFeePercentNumerator: 5,
        liquidationFeePercentDenominator: 100,
    };
    const IsolatedMargin = await hre.ethers.getContractFactory("IsolatedMargin");
    const isolatedMargin = await IsolatedMargin.deploy(...Object.values(constructorArgs));
    config.isolatedMarginAddress = isolatedMargin.address;
    console.log("Deployed: Isolated margin");
    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
