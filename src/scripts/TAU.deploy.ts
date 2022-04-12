import hre from "hardhat";

async function main() {
    await hre.run("compile");

    const TAU = await hre.ethers.getContractFactory("TorqueTAU");
    const instance = await hre.upgrades.deployProxy(TAU, []);
    await instance.deployed();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
