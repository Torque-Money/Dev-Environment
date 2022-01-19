import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType} from "../util/chooseConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const marginLong = await hre.ethers.getContractAt("MarginLong", config.marginLongAddress);

    const marginApprovedCollateral = config.approved.filter((approved) => approved.marginLongCollateral).map((approved) => approved.address);
    const marginSupportedCollateral = Array(marginApprovedCollateral.length).fill(true);
    await marginLong.setApprovedCollateral(marginApprovedCollateral, marginSupportedCollateral);

    const marginApprovedBorrow = config.approved.filter((approved) => approved.marginLongBorrow).map((approved) => approved.address);
    const marginSupportedBorrow = Array(marginApprovedBorrow.length).fill(true);
    await marginLong.setApprovedBorrowed(marginApprovedBorrow, marginSupportedBorrow);

    console.log("Setup: Margin long");
}
