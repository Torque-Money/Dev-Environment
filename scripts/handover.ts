import hre from "hardhat";
import config from "../config.json";

export default async function main() {
    // Hand the contracts over to the DAO and remove centralization
    const pool = await hre.ethers.getContractAt("LPool", config.poolAddress);
    const margin = await hre.ethers.getContractAt("Margin", config.marginAddress);
    const token = await hre.ethers.getContractAt("Token", config.tokenAddress);
    const timelock = await hre.ethers.getContractAt("Timelock", config.timelockAddress);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    // Set pool admin as timelock and revoke admin and default admin roles
    await pool.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN_ROLE")), timelock.address);
    await pool.renounceRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN_ROLE")), signerAddress);

    // Set margin owner as timelock
    await margin.transferOwnership(timelock.address);

    // Set the token owner as the timelock
    await token.transferOwnership(timelock.address);

    // Remove priveliges from the timelock
    await pool.renounceRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TIMELOCK_ADMIN_ROLE")), signerAddress);
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
