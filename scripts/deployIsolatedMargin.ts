import hre from "hardhat";
import fs from "fs";
import config from "../config.json";

export default async function main() {
    const constructorArgs = {
        taxPercentNumerator: 5,
        taxPercentDenominator: 100,
        blocksPerCompound: 2.628e6 / config.avgBlockTime,
    };
    const IsolatedMargin = await hre.ethers.getContractFactory("IsolatedMargin");
    const isolatedMargin = await IsolatedMargin.deploy(...Object.values(constructorArgs));
    // @ts-ignore
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
