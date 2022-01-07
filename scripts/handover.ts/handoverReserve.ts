import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const reserve = await hre.ethers.getContractAt("Reserve", config.reserveAddress);

    await reserve.transferOwnership(config.timelockAddress);

    console.log("Handover: Reserve");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
