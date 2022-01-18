import deployPool from "./deployPool";
import deployOracle from "./deployOracle";
import deployConverter from "./deployConverter";
import deployMarginLong from "./deployMarginLong";
import deployResolver from "./deployResolver";
import {HardhatRuntimeEnvironment} from "hardhat/types";

export default async function main(test: boolean, hre: HardhatRuntimeEnvironment) {
    await deployConverter(test, hre);
    await deployPool(test, hre);
    await deployOracle(test, hre);
    await deployMarginLong(test, hre);
    await deployResolver(test, hre);
}
