import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ConfigType} from "../utils/utilConfig";

import deployPool from "./deployPool";
import deployOracle from "./deployOracle";
import deployConverter from "./deployConverter";
import deployMarginLong from "./deployMarginLong";
import deployResolver from "./deployResolver";
import deployFlashLender from "./deployFlashLender";
import deployTimelock from "./deployTimelock";
import deployLPToken from "./deployLPToken";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    await deployConverter(configType, hre);
    await deployOracle(configType, hre); // **** So now we actually need a way of being able to set the oracle directly - perhaps we need to do this in the setup script
    await deployPool(configType, hre);
    await deployLPToken(configType, hre);
    await deployMarginLong(configType, hre);
    await deployResolver(configType, hre);
    await deployFlashLender(configType, hre);
    await deployTimelock(configType, hre);
}
