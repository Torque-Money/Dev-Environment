import hre from "hardhat";
import fs from "fs";
import config from "../config.json";

export default async function main() {
    // Call all of the setup functions, approve tokens, and handover to DAO
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
