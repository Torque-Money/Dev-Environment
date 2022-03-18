import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../utils/config/utilConfig";
import {getFilteredTokenAddresses} from "../utils/tokens/utilGetTokens";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress);

    await (await marginLong.setPool(config.contracts.leveragePoolAddress)).wait();
    console.log("-- Set pool");
    await (await marginLong.setOracle(config.contracts.oracleAddress)).wait();
    console.log("-- Set oracle");

    const marginApprovedCollateral = getFilteredTokenAddresses(config, "marginLongCollateral");
    await (await marginLong.addCollateralToken(marginApprovedCollateral)).wait();
    console.log("-- Add collateral tokens");
    const marginSupportedCollateral = Array(marginApprovedCollateral.length).fill(true);
    await (await marginLong.setApprovedCollateralToken(marginApprovedCollateral, marginSupportedCollateral)).wait();
    console.log("-- Set approved collateral tokens");

    const marginApprovedBorrow = getFilteredTokenAddresses(config, "marginLongBorrow");
    await (await marginLong.addBorrowToken(marginApprovedBorrow)).wait();
    console.log("-- Add borrow tokens");
    const marginSupportedBorrow = Array(marginApprovedBorrow.length).fill(true);
    await (await marginLong.setApprovedBorrowToken(marginApprovedBorrow, marginSupportedBorrow)).wait();
    console.log("-- Set approved borrow tokens");

    console.log("Setup: MarginLong");
}
