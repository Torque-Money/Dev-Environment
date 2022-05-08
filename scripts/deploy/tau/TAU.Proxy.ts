import hre from "hardhat";

async function main() {
    const TAU = await hre.ethers.getContractFactory("TorqueTAU");
    const tau = (await hre.upgrades.deployProxy(TAU, ["10000000000000000000000000"]));
    await tau.deployed();

    console.log("Deploy | TAU | Proxy | Proxy:", tau.address);
    console.log("Deploy | TAU | Proxy | Implementation:", await hre.upgrades.erc1967.getImplementationAddress(tau.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
