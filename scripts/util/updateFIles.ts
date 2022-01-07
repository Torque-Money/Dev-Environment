import fs from "fs";

export default async function main() {
    const compiledContracts = "artifacts/contracts";
    const config = "config.json";
    const abis = [];
    const outDir = "../Torque-Frontend/src/config";

    console.log("Util: Copied files");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
