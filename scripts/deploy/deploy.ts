import deployPool from "./deployPool";
import deployOracle from "./deployOracle";
import deployConverter from "./deployConverter";
import deployMarginLong from "./deployMarginLong";
import deployResolver from "./deployResolver";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {ConfigType} from "../util/utilChooseConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    await deployConverter(configType, hre);
    await deployPool(configType, hre);
    await deployOracle(configType, hre);
    await deployMarginLong(configType, hre);
    await deployResolver(configType, hre);
}
