import {HardhatRuntimeEnvironment} from "hardhat/types";
import {ConfigType} from "../util/utilConfig";

import setupPool from "./setupPool";
import setupOracle from "./setupOracle";
import setupMarginLong from "./setupMarginLong";
import setupTimelock from "./setupTimelock";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    // await setupPool(configType, hre);
    // await setupOracle(configType, hre);
    // await setupMarginLong(configType, hre);
    // await setupTimelock(configType, hre); // **** THIS HAS NOT BEEN RUN YET - IT IS NOT SETUP TO WORK WITH THE TIMELOCK
}
