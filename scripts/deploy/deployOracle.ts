import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../utils/config/utilConfig";

import deployOracleMain from "./deployOracleMain";
import deployOracleTest from "./deployOracleTest";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    // Deploy either the test or the main contract depending on the network deployed on
    if (configType === "main") deployOracleMain(configType, hre);
    else deployOracleTest(configType, hre);
}
