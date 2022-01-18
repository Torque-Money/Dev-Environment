import hre from "hardhat";
import {chooseConfig, saveConfig} from "../util/chooseConfig";

export default async function main(test: boolean = false) {
    const config = chooseConfig(test);

    const constructorArgs = {
        thresholdNumerator: 1,
        thresholdDenominator: 200,
        priceDecimals: 18,
    };
    const Oracle = await hre.ethers.getContractFactory("Oracle");
    const oracle = await Oracle.deploy(...Object.values(constructorArgs));
    config.oracleAddress = oracle.address;
    console.log("Deployed: Oracle");

    saveConfig(config, test);
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
