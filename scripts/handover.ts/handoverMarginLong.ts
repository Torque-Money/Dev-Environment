import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const marginLong = await hre.ethers.getContractAt("MarginLong", config.marginLongAddress);

    await marginLong.transferOwnership(config.timelockAddress);

    console.log("Handover: Margin long");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
