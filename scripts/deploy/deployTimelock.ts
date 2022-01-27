import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const constructorArgs = {
        // converter: config.converterAddress,
        // oracle: config.oracleAddress,
        // taxPercentNumerator: 5,
        // taxPercentDenominator: 100,
        // timePerInterestApplication: hre.ethers.BigNumber.from(2628000),
    };

    // const Pool = await hre.ethers.getContractFactory("LPool");
    // const pool = await hre.upgrades.deployProxy(Pool, Object.values(constructorArgs));

    // config.leveragePoolAddress = pool.address;
    // config.leveragePoolResolvedAddress = await pool.resolvedAddress;
    // console.log(`Deployed: Pool proxy and pool | ${pool.address} ${await pool.resolvedAddress}`);

    if (configType !== "fork") saveTempConstructor(await pool.resolvedAddress, {});
    saveConfig(config, configType);
}
