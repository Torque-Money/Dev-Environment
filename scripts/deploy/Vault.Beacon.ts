import hre from "hardhat";

async function main() {
    const Vault = await hre.ethers.getContractFactory("Vault");
    const beacon = await hre.upgrades.deployBeacon(Vault);
    await beacon.deployed();

    console.log("Deploy | Vault | Beacon | Beacon:", beacon.address);
    console.log("Deploy | Vault | Beacon | Implementation:", await hre.upgrades.beacon.getImplementationAddress(beacon.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
