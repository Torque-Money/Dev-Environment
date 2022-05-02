import hre from "hardhat";

async function main() {
    const BeefyLPStrategy = await hre.ethers.getContractFactory("BeefyLPStrategy");
    const beacon = await hre.upgrades.deployBeacon(BeefyLPStrategy);
    await beacon.deployed();

    // **** First of all we need to get the strategy 

    const beacon = await hre.upgrades.

    console.log("BeefyLPStrategy beacon:", beacon.address);
    console.log("BeefyLPStrategy implementation:", await hre.upgrades.beacon.getImplementationAddress(beacon.address));

    const beacon = 
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
