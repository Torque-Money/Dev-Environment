import hre from "hardhat";

import { TorqueTAU } from "../../typechain-types";

import { loadData, saveData } from "./utils/data";

async function main() {
    const data = loadData();

    const TAU = await hre.ethers.getContractFactory("TorqueTAU");
    const tau = (await hre.upgrades.deployProxy(TAU, [data.config.TAUInitialSupply])) as TorqueTAU;
    await tau.deployed();

    data.contracts.TAU.implementation = await hre.upgrades.erc1967.getImplementationAddress(tau.address);
    data.contracts.TAU.proxy = tau.address;

    console.log("TAU implementation:", data.contracts.TAU.implementation);
    console.log("TAU proxy:", data.contracts.TAU.proxy);

    saveData(data);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
