import hre from "hardhat";

import approve from "./approve";
import deployDao from "./deployDao";
import deployMargin from "./deployMargin";
import deployOracle from "./deployOracle";
import deployPool from "./deployPool";
import deployTimelock from "./deployTimelock";
import deployToken from "./deployToken";
import deployYield from "./deployYield";
import fund from "./fund";
import handover from "./handover";

async function main() {
    // Protocol
    await deployOracle();
    await deployPool();
    await deployMargin();

    // DAO
    await deployYield();
    await deployToken();
    await deployDao();
    await deployTimelock();

    // Setup
    await approve();
    await fund();

    await handover();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
