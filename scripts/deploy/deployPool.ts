import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, saveConfig} from "../util/chooseConfig";

export default async function main(test: boolean, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(test);

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
    console.log("Deployed: Pool");

    saveConfig(config, test);
}
