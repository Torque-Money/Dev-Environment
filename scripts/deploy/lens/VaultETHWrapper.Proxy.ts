import hre from "hardhat";

async function main() {
    const VaultETHWrapper = await hre.ethers.getContractFactory("VaultETHWrapper");
    const vaultETHWrapper = (await hre.upgrades.deployProxy(VaultETHWrapper, ["0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83"]));
    await vaultETHWrapper.deployed();

    console.log("Deploy | VaultETHWrapper | Proxy | Proxy:", vaultETHWrapper.address);
    console.log("Deploy | VaultETHWrapper | Proxy | Implementation:", await hre.upgrades.erc1967.getImplementationAddress(vaultETHWrapper.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
