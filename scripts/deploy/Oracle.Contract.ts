import hre from "hardhat";

async function main() {
    const link = "0xb3654dc3D10Ea7645f8319668E8F54d2574FBdC8";

    const Oracle = await hre.ethers.getContractFactory("Oracle");
    const oracle = await Oracle.deploy(link);
    await oracle.deployed();

    console.log("Deploy | Oracle | Contract | Contract:", oracle.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
