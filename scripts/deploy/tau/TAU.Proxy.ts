import hre from "hardhat";

import { TorqueTAU } from "../../../typechain-types";

async function main() {
    const TAU = await hre.ethers.getContractFactory("TorqueTAU");
    const tau = (await hre.upgrades.deployProxy(TAU, ["10000000000000000000000000"])) as TorqueTAU;
    await tau.deployed();

    console.log("TAU proxy:", tau.address);
    console.log("TAU implementation:", await hre.upgrades.erc1967.getImplementationAddress(tau.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
