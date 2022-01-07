import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const isolatedMargin = await hre.ethers.getContractAt("IsolatedMargin", config.isolatedMarginAddress);

    const marginApproved = config.approved.filter((approved) => approved.margin).map((approved) => approved.address);
    const marginSupported = Array(marginApproved.length).fill(true);
    await isolatedMargin.approve(marginApproved, marginSupported);

    console.log("Setup: Isolated margin");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
