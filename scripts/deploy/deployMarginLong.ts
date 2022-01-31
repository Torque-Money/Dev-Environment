import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const constructorArgs = {
        pool: config.leveragePoolAddress,
        oracle: config.oracleAddress,
        minCollateralPrice: hre.ethers.BigNumber.from(10).pow(18).mul(100),
        maxLeverageNumerator: 125,
        maxLeverageDenominator: 1,
        liquidationFeePercentNumerator: 10,
        liquidationFeePercentDenominator: 100,
    };

    const MarginLong = await hre.ethers.getContractFactory("MarginLong");
    const marginLong = await hre.upgrades.deployProxy(MarginLong, Object.values(constructorArgs));

    config.marginLongAddress = marginLong.address;
    config.marginLongLogicAddress = await getImplementationAddress(hre.ethers.provider, marginLong.address);
    console.log(`Deployed: Margin long proxy and margin long | ${marginLong.address} ${config.marginLongLogicAddress}`);

    if (configType !== "fork") saveTempConstructor(config.marginLongLogicAddress, {});
    saveConfig(config, configType);
}
