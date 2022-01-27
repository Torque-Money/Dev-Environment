import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType} from "../util/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const marginLong = await hre.ethers.getContractAt("MarginLong", config.marginLongAddress);

    const marginApprovedCollateral = config.approved.filter((approved) => approved.marginLongCollateral).map((approved) => approved.address);
    await marginLong.addCollateralToken(marginApprovedCollateral);
    const marginSupportedCollateral = Array(marginApprovedCollateral.length).fill(true);
    await marginLong.setApprovedCollateralToken(marginApprovedCollateral, marginSupportedCollateral);

    const marginApprovedBorrow = config.approved.filter((approved) => approved.marginLongBorrow).map((approved) => approved.address);
    await marginLong.addBorrowedToken(marginApprovedBorrow);
    const marginSupportedBorrow = Array(marginApprovedBorrow.length).fill(true);
    await marginLong.setApprovedBorrowedToken(marginApprovedBorrow, marginSupportedBorrow);

    console.log("Setup: Margin long");
}
