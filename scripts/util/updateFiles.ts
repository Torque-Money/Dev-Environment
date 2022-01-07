import fs from "fs";

export default async function main() {
    const compiledContracts = process.cwd() + "/artifacts/contracts";
    const config = process.cwd() + "/config.json";
    const abis = [
        "FlashSwap/FlashSwap.sol/FlashSwap.json",
        "FlashSwap/FlashSwapDefault.sol/FlashSwapDefault.json",
        "Governance/Governor.sol/Governance.json",
        "Governance/Timelock.sol/Timelock.json",
        "Governance/Token.sol/Token.json",
        "LPool/LPool.sol/LPool.json",
        "MarginLong/MarginLong.sol/MarginLong.json",
        "Oracle/Oracle.sol/Oracle.json",
        "Reserve/Reserve.sol/Reserve.json",
    ];
    const outDir = process.cwd() + "/../Torque-Frontend/src/config";

    // Loop through each ABI and copy it to the new directory
    for (const abi of abis) {
        const oldPath = compiledContracts + "/" + abi;

        const fileName = abi.split("/").at(-1);
        const newPath = outDir + "/" + fileName;

        fs.copyFile(oldPath, newPath, (err) => {
            if (err) throw err;
        });

        console.log(`Moved '${oldPath}' to '${newPath}'`);
    }

    // Copy the config
    const newConfigPath = outDir + "/" + config.split("/").at(-1);
    fs.copyFile(config, newConfigPath, (err) => {
        if (err) throw err;
    });
    console.log(`Moved '${config}' to '${newConfigPath}'`);

    console.log("Util: Copied files");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
