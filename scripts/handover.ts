// **** This will be responsible for handing the protocol over to the DAO to be operated

import hre from "hardhat";
import config from "../config.json";

export default async function main() {
    // Hand the contracts over to the DAO, approve funds to exit, and renounce admin of the timelock
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
