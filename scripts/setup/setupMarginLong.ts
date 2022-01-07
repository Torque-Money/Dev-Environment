import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const marginLong = await hre.ethers.getContractAt("IsolatedMargin", config.marginLongAddress);

    const marginApproved = config.approved.filter((approved) => approved.marginLong).map((approved) => approved.address);
    const marginSupported = Array(marginApproved.length).fill(true);
    await marginLong.approve(marginApproved, marginSupported);

    console.log("Setup: Margin long");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
