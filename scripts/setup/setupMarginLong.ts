import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const marginLong = await hre.ethers.getContractAt("IsolatedMargin", config.marginLongAddress);

    const marginApprovedCollateral = config.approved.filter((approved) => approved.marginLong).map((approved) => approved.address);
    const marginSupportedCollateral = Array(marginApprovedCollateral.length).fill(true);
    await marginLong.setApprovedCollateral(marginApprovedCollateral, marginSupportedCollateral);

    const marginApprovedBorrow = config.approved.filter((approved) => approved.leveragePool).map((approved) => approved.address);
    const marginSupportedBorrow = Array(marginApprovedBorrow.length).fill(true);
    await marginLong.setApprovedBorrow(marginApprovedBorrow, marginSupportedBorrow);

    console.log("Setup: Margin long");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
