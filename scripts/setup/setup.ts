import setupPool from "./setupPool";
import setupOracle from "./setupOracle";
import setupMarginLong from "./setupMarginLong";
import {HardhatRuntimeEnvironment} from "hardhat/types";

export default async function main(test: boolean, hre: HardhatRuntimeEnvironment) {
    await setupPool(test);
    await setupOracle(test);
    await setupMarginLong(test);
}
