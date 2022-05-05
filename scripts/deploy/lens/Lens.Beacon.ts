import hre from "hardhat";

async function main() {
    const Lens = await hre.ethers.getContractFactory("Lens");
    const beacon = await hre.upgrades.deployBeacon(Lens);
    await beacon.deployed();

    console.log("Deploy | Lens | Beacon | Beacon:", beacon.address);
    console.log("Deploy | Lens | Beacon | Implementation:", await hre.upgrades.beacon.getImplementationAddress(beacon.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
