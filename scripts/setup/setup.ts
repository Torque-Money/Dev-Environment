import setupPool from "./setupPool";
import setupOracle from "./setupOracle";
import setupMarginLong from "./setupMarginLong";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {ConfigType} from "../util/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    await setupPool(configType, hre);
    await setupOracle(configType, hre);
    await setupMarginLong(configType, hre);
}
