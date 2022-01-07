import fs from "fs";

function move() {}

export default async function main() {
    const compiledContracts = "artifacts/contracts";
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
    const outDir = process.cwd() + "../Torque-Frontend/src/config";

    // Here we are going to loop through each ABI, take its file name from the path and move it into the outDir

    console.log("Util: Copied files");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
