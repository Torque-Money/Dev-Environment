import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ConfigType} from "../utils/config/utilConfig";

import setupPool from "./setupPool";
import setupOracle from "./setupOracle";
import setupMarginLong from "./setupMarginLong";
import setupTimelock from "./setupTimelock";
import setupFlashLender from "./setupFlashLender";
import setupResolver from "./setupResolver";
import setupMultisig from "./setupMultisig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    await setupOracle(configType, hre);
    await setupPool(configType, hre);
    await setupMarginLong(configType, hre);
    await setupResolver(configType, hre);
    await setupFlashLender(configType, hre);

    await setupTimelock(configType, hre);
    await setupMultisig(configType, hre);
}
