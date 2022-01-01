import hre from "hardhat";
import fs from "fs";
import config from "../config.json";

export default async function main() {
    const constructorArgs1 = {
        // @ts-ignore
        pool: config.poolAddress,
    };
    const FlashSwap = await hre.ethers.getContractFactory("FlashSwap");
    const flashSwap = await FlashSwap.deploy(...Object.values(constructorArgs1));
    // @ts-ignore
    config.flashSwapAddress = flashSwap.address;
    console.log("Deployed: Flash swap");
    fs.writeFileSync("config.json", JSON.stringify(config));

    const constructorArgs2 = {
        router: config.defaultRouterAddress,
        // @ts-ignore
        pool: config.poolAddress,
    };
    const FlashSwapDefault = await hre.ethers.getContractFactory("FlashSwapDefault");
    const flashSwapDefault = await FlashSwapDefault.deploy(...Object.values(constructorArgs2));
    // @ts-ignore
    config.flashSwapDefaultAddress = flashSwapDefault.address;
    console.log("Deployed: Flash swap default");
    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
