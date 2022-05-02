import hre from "hardhat";

async function main() {
    const VaultV1 = await hre.ethers.getContractFactory("TorqueVaultV1");
    const beacon = await hre.upgrades.deployBeacon(VaultV1);
    await beacon.deployed();

    console.log("Deploy VaultV1 | Beacon:", beacon.address);
    console.log("Deploy VaultV1 | Implementation:", await hre.upgrades.beacon.getImplementationAddress(beacon.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
