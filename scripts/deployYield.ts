import hre from "hardhat";
import fs from "fs";
import config from "../config.json";

export default async function main() {
    const constructorArgs = {
        // @ts-ignore
        token: config.tokenAddress,
        // @ts-ignore
        pool: config.poolAddress,
    };
    const Yield = await hre.ethers.getContractFactory("Yield");
    const _yield = await Yield.deploy(...Object.values(constructorArgs));
    // @ts-ignore
    config.yieldAddress = _yield.address;
    console.log("Deployed: Yield");
    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
