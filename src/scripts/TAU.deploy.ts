import hre from "hardhat";

async function main() {
    await hre.run("compile");

    // const TAU = await hre.ethers.getContractAt("");
    const greeter = await Greeter.deploy("Hello, Hardhat!");

    await greeter.deployed();

    console.log("Greeter deployed to:", greeter.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
