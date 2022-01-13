import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const converter = await hre.ethers.getContractAt("Converter", config.converterAddress);

    await converter.transferOwnership(config.timelockAddress);

    console.log("Handover: Converter");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
