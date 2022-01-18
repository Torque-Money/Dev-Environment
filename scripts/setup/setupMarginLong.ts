import hre from "hardhat";
import {chooseConfig} from "../util/chooseConfig";

export default async function main(test: boolean = false) {
    const config = chooseConfig(test);

    const marginLong = await hre.ethers.getContractAt("MarginLong", config.marginLongAddress);

    const marginApprovedCollateral = config.approved.filter((approved) => approved.marginLongCollateral).map((approved) => approved.address);
    const marginSupportedCollateral = Array(marginApprovedCollateral.length).fill(true);
    await marginLong.setApprovedCollateral(marginApprovedCollateral, marginSupportedCollateral);

    const marginApprovedBorrow = config.approved.filter((approved) => approved.marginLongBorrow).map((approved) => approved.address);
    const marginSupportedBorrow = Array(marginApprovedBorrow.length).fill(true);
    await marginLong.setApprovedBorrowed(marginApprovedBorrow, marginSupportedBorrow);

    console.log("Setup: Margin long");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
