import hre from "hardhat";

import { TorqueTAU } from "../../typechain-types";

import { loadData, saveData } from "./utils/data";

async function main() {
    await hre.run("compile");

    const data = loadData();

    const TAU = await hre.ethers.getContractFactory("TorqueTAU");
    const tau = (await hre.upgrades.deployProxy(TAU, [data.config.TAUInitialSupply])) as TorqueTAU;
    await tau.deployed();

    // **** Just do a few more tests to make sure that the token works before attempting to deploy to mainnet

    data.contracts.TAU = tau.address;
    saveData(data);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
