import hre from "hardhat";
import config from "../config.json";

import deployGovernance from "./deployGovernance";
import deployTimelock from "./deployTimelock";
import deployToken from "./deployToken";
import deployYield from "./deployYield";

async function main() {
    // Governance
    await deployToken();
    await deployYield();
    await deployGovernance();
    await deployTimelock();

    // Custom handover from token and timelock
    const timelock = await hre.ethers.getContractAt("Timelock", config.timelockAddress);
    const token = await hre.ethers.getContractAt("Token", config.tokenAddress);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    await token.transferOwnership(timelock.address);
    console.log("Transferred token ownership to timelock");

    await timelock.renounceRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TIMELOCK_ADMIN_ROLE")), signerAddress);
    console.log("Renounced admin role from timelock");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
