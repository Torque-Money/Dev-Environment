import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const constructorArgs = {
        converter: config.converterAddress,
        oracle: config.oracleAddress,
        taxPercentNumerator: 5,
        taxPercentDenominator: 100,
        timePerInterestApplication: hre.ethers.BigNumber.from(10).pow(4).mul(3154),
    };

    const Pool = await hre.ethers.getContractFactory("LPool");
    const pool = await hre.upgrades.deployProxy(Pool, Object.values(constructorArgs));

    config.leveragePoolAddress = pool.address;
    config.leveragePoolLogicAddress = await getImplementationAddress(hre.ethers.provider, pool.address);
    console.log(`Deployed: Pool proxy and pool | ${pool.address} ${config.leveragePoolLogicAddress}`);

    if (configType !== "fork") saveTempConstructor(config.leveragePoolLogicAddress, {});
    saveConfig(config, configType);
}
