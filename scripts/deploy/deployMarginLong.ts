import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

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
    console.log(`Deployed: Margin long | ${marginLong.address}`);

    if (configType !== "fork") saveTempConstructor(marginLong.address, constructorArgs);
    saveConfig(config, configType);
}
