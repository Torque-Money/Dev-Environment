import hre from "hardhat";
import fs from "fs";
import config from "../config.json";

export default async function main() {
    const constructorArgs = {
        pool: config.leveragePoolAddress,
    };
    const Oracle = await hre.ethers.getContractFactory("Oracle");
    const oracle = await Oracle.deploy(...Object.values(constructorArgs));
    config.oracleAddress = oracle.address;
    console.log("Deployed: Oracle");
    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
