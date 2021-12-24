import hre from "hardhat";
import config from "../config.json";

export default async function main() {
    // Hand the contracts over to the DAO and remove centralization
    const pool = await hre.ethers.getContractAt("LPool", config.poolAddress);
    const margin = await hre.ethers.getContractAt("Margin", config.marginAddress);
    const token = await hre.ethers.getContractAt("Token", config.tokenAddress);
    const dao = await hre.ethers.getContractAt("Governance", config.tokenAddress);
    const timelock = await hre.ethers.getContractAt("Timelock", config.timelockAddress);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    // Set pool admin as timelock and revoke admin and default admin roles
    await pool.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN")), timelock.address);
    await pool.renounceRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN")), signerAddress);
    await pool.renounceRole(hre.ethers.utils.hexZeroPad(hre.ethers.utils.toUtf8Bytes("0"), 32), signerAddress);

    // Set margin owner as timelock
    await margin.transferOwnership(timelock.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
