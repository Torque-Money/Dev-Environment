import hre from "hardhat";

import config from "../../config";

async function main() {
    await hre.run("compile");

    const TAU = await hre.ethers.getContractFactory("TorqueTAU");
    const instance = await hre.upgrades.deployProxy(TAU, [config.TAUInitialSupply]);
    await instance.deployed();

    console.log(instance.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
