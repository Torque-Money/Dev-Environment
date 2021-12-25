import hre from "hardhat";

import deployGovernance from "./deployGovernance";
import deployTimelock from "./deployTimelock";
import deployToken from "./deployToken";
import deployYield from "./deployYield";

async function main() {
    // Governance
    await deployToken();
    await deployYield();
    await deployGovernance();
    await deployTimelock();

    // Custom handover
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
