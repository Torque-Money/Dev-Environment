import {HardhatRuntimeEnvironment} from "hardhat/types";

import deployOracleMain from "./deployOracleMain";
import deployOracleTest from "./deployOracleTest";

import {ConfigType} from "../utils/config/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    // Deploy either the test or the main contract depending on the network deployed on
    if (configType === "main") deployOracleMain(configType, hre);
    else deployOracleTest(configType, hre);
}
