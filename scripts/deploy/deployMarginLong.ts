import {HardhatRuntimeEnvironment} from "hardhat/types";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

import {chooseConfig, ConfigType, saveConfig} from "../utils/utilConfig";
import {saveTempConstructor} from "../utils/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const constructorArgs = {
        pool: config.contracts.leveragePoolAddress,
        oracle: config.contracts.oracleAddress,
        minCollateralPrice: hre.ethers.BigNumber.from(10).pow(18).mul(100),
        maxLeverageNumerator: 125,
        maxLeverageDenominator: 1,
        liquidationFeePercentNumerator: 5,
        liquidationFeePercentDenominator: 100,
    };

    const MarginLong = await hre.ethers.getContractFactory("MarginLong");
    const marginLong = await hre.upgrades.deployProxy(MarginLong, Object.values(constructorArgs));
    await marginLong.deployed();

    config.contracts.marginLongAddress = marginLong.address;
    const implementation = await getImplementationAddress(hre.ethers.provider, marginLong.address);
    console.log(`Deployed: MarginLong, implementation | ${marginLong.address}, ${implementation}`);

    if (configType !== "fork") saveTempConstructor(implementation, {});
    saveConfig(config, configType);
}
