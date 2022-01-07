import hre from "hardhat";
import fs from "fs";
import config from "../../config.json";

export default async function main() {
    const constructorArgs1 = {};
    const FlashSwap = await hre.ethers.getContractFactory("FlashSwap");
    const flashSwap = await FlashSwap.deploy(...Object.values(constructorArgs1));
    config.flashSwapAddress = flashSwap.address;
    console.log("Deployed: Flash swap");

    const constructorArgs2 = {
        router: config.defaultRouterAddress,
    };
    const FlashSwapDefault = await hre.ethers.getContractFactory("FlashSwapDefault");
    const flashSwapDefault = await FlashSwapDefault.deploy(...Object.values(constructorArgs2));
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
