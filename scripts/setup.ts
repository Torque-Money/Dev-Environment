import hre from "hardhat";
import fs from "fs";
import config from "../config.json";

import deployPool from "./deployPool";
import deployOracle from "./deployOracle";
import deployFlashSwap from "./deployFlashSwap";
import deployIsolatedMargin from "./deployIsolatedMargin";
import deployGovernance from "./deployGovernance";
import deployYield from "./deployYield";

export default async function main() {
    // Deploy contracts
    await deployPool();
    await deployOracle();
    await deployFlashSwap();
    await deployIsolatedMargin();
    await deployGovernance();
    await deployYield();

    // Approve tokens for use with the contracts

    // Remove ownership of the contracts
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
