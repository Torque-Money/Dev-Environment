import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../utils/utilConfig";
// import {saveTempConstructor} from "../utils/utilVerify";
// import {getImplementationAddress} from "@openzeppelin/upgrades-core";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    // **** Here we are going to use a beacon proxy and deploy new tokens off of it

    // const constructorArgs = {
    //     converter: config.converterAddress,
    //     oracle: config.oracleAddress,
    //     taxPercentNumerator: 5,
    //     taxPercentDenominator: 100,
    //     timePerInterestApplication: hre.ethers.BigNumber.from(86400).mul(365),
    // };

    // const Pool = await hre.ethers.getContractFactory("LPool");
    // const pool = await hre.upgrades.deployProxy(Pool, Object.values(constructorArgs));
    // await pool.deployed();

    // config.leveragePoolAddress = pool.address;
    // config.leveragePoolLogicAddress = await getImplementationAddress(hre.ethers.provider, pool.address);
    // console.log(`Deployed: Pool proxy and pool | ${pool.address} ${config.leveragePoolLogicAddress}`);

    // if (configType !== "fork") saveTempConstructor(config.leveragePoolLogicAddress, {});
    // saveConfig(config, configType);
}
