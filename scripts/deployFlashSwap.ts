import hre from "hardhat";
import fs from "fs";
import config from "../config.json";

export default async function main() {
    const constructorArgs = {
        // @ts-ignore
        pool: config.poolAddress,
    };
    const FlashSwap = await hre.ethers.getContractFactory("FlashSwap");
    const flashSwap = await FlashSwap.deploy(...Object.values(constructorArgs));
    // @ts-ignore
    config.flashSwapAddress = flashSwap.address;
    console.log("Deployed: Flash swap");
    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
