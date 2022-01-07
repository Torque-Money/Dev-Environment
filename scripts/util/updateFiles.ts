import fs from "fs";

export default async function main() {
    const compiledContracts = process.cwd() + "/artifacts/contracts";
    const config = "config.json";
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

    console.log(compiledContracts);

    // Loop through each ABI and copy it to the new directory
    for (const abi of abis) {
    }

    // Move the config

    console.log("Util: Copied files");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
