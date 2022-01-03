import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const flashSwapDefault = await hre.ethers.getContractAt("FlashSwapDefault", config.flashSwapDefaultAddress);

    await flashSwapDefault.transferOwnership(config.timelockAddress);

    console.log("Setup: Flash swap / flash swap default");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
