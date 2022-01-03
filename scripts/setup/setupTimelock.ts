import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    // Get the deployer contracts
    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const timelock = await hre.ethers.getContractAt("Timelock", config.timelockAddress);

    await timelock.renounceRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TIMELOCK_ADMIN_ROLE")), signerAddress);
    console.log("Setup timelock: Finishing assigning roles");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
