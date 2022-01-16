import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const oracle = await hre.ethers.getContractAt("Oracle", config.oracleAddress);

    await oracle.transferOwnership(config.timelockAddress);

    console.log("Handover: Oracle");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
