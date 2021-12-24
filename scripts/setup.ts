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
    await deployPool();
    await deployOracle();
    await deployMargin();

    await deployYield();
    await deployToken();
    await deployDao();
    await deployTimelock();

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
