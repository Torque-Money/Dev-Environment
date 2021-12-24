import hre from "hardhat";
import config from "../config.json";

export default async function main() {
    // Hand the contracts over to the DAO, approve funds to exit, and renounce admin of the timelock
    // **** Quickly do this tommorow

    // Revoke:
    // Pool
    // Margin
    // Token
    // DAO
    // Timelock

    const pool = hre.ethers.getContractAt("LPool", config.poolAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
