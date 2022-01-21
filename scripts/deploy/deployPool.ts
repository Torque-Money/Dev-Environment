import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const constructorArgs = {
        converter: config.converterAddress,
        taxPercentNumerator: 5,
        taxPercentDenominator: 100,
        blocksPerInterestApplication: hre.ethers.BigNumber.from(2628000).div(config.avgBlockTime),
    };
    const Pool = await hre.ethers.getContractFactory("LPool");
    const pool = await Pool.deploy(
        constructorArgs.converter,
        constructorArgs.taxPercentNumerator,
        constructorArgs.taxPercentDenominator,
        constructorArgs.blocksPerInterestApplication
    );
    config.leveragePoolAddress = pool.address;
    console.log(`Deployed: Pool | ${pool.address}`);

    saveTempConstructor(pool.address, constructorArgs);
    saveConfig(config, configType);
}
