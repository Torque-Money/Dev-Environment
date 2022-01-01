import hre from "hardhat";
import fs from "fs";
import config from "../config.json";

export default async function main() {
    const constructorArgs = {};
    const Pool = await hre.ethers.getContractFactory("LPool");
    const pool = await Pool.deploy(...Object.values(constructorArgs));
    // @ts-ignore
    config.poolAddress = pool.address;
    console.log("Deployed: Pool");
    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
