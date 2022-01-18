import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, saveConfig} from "../util/chooseConfig";

export default async function main(test: boolean, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(test);

    const constructorArgs = {
        pool: config.leveragePoolAddress,
        oracle: config.oracleAddress,
        minMarginLevelPercentNumerator: 105,
        minMarginLevelPercentDenominator: 100,
        minCollateralPrice: hre.ethers.BigNumber.from(10).pow(18).mul(100),
        maxLeverage: 125,
        liquidationFeePercentNumerator: 10,
        liquidationFeePercentDenominator: 100,
    };

    const MarginLong = await hre.ethers.getContractFactory("MarginLong");
    const marginLong = await MarginLong.deploy(
        constructorArgs.pool,
        constructorArgs.oracle,
        constructorArgs.minMarginLevelPercentNumerator,
        constructorArgs.minMarginLevelPercentDenominator,
        constructorArgs.minCollateralPrice,
        constructorArgs.maxLeverage,
        constructorArgs.liquidationFeePercentNumerator,
        constructorArgs.liquidationFeePercentDenominator
    );
    config.marginLongAddress = marginLong.address;
    console.log("Deployed: Margin long");

    saveConfig(config, test);
}
