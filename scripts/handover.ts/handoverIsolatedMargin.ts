import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const isolatedMargin = await hre.ethers.getContractAt("IsolatedMargin", config.isolatedMarginAddress);

    await isolatedMargin.transferOwnership(config.timelockAddress);

    console.log("Handover: Isolated margin");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
