import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType} from "../utils/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress);

    const marginApprovedCollateral = config.tokens.approved.filter((approved) => approved.marginLongCollateral).map((approved) => approved.address);
    await (await marginLong.addCollateralToken(marginApprovedCollateral)).wait();
    const marginSupportedCollateral = Array(marginApprovedCollateral.length).fill(true);
    await (await marginLong.setApprovedCollateralToken(marginApprovedCollateral, marginSupportedCollateral)).wait();

    const marginApprovedBorrow = config.tokens.approved.filter((approved) => approved.marginLongBorrow).map((approved) => approved.address);
    await (await marginLong.addBorrowToken(marginApprovedBorrow)).wait();
    const marginSupportedBorrow = Array(marginApprovedBorrow.length).fill(true);
    await (await marginLong.setApprovedBorrowToken(marginApprovedBorrow, marginSupportedBorrow)).wait();

    console.log("Setup: MarginLong");
}
