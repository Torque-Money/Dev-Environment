import hre from "hardhat";

import data from "../../data/data.json";
import { TorqueTAU } from "../../typechain-types";

async function main() {
    await hre.run("compile");

    const TAU = await hre.ethers.getContractFactory("TorqueTAU");
    const tau = (await hre.upgrades.deployProxy(TAU, [config.TAUInitialSupply])) as TorqueTAU;
    await tau.deployed();

    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    console.log(await tau.balanceOf(signerAddress));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
