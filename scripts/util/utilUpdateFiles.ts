import fs from "fs-extra";

export default async function main() {
    const compiledContracts = process.cwd() + "/artifacts/contracts";
    const configs = [process.cwd() + "/config.main.json", process.cwd() + "/config.test.json", process.cwd() + "/config.fork.json"];
    const abis = [
        "/v1/LPool/LPool.sol/LPool.json",
        "/v1/MarginLong/MarginLong.sol/MarginLong.json",
        "/Oracle/IOracle.sol/IOracle.json",
        "/Converter/Converter.sol/Converter.json",
    ];
    const typeChain = process.cwd() + "/typechain-types";

    const outRoot = process.cwd() + "/../Torque-dApp";
    const outConfigDir = outRoot + "/config";

    for (const abi of abis) {
        const oldPath = compiledContracts + abi;

        const fileName = abi.split("/").at(-1);
        const newPath = outConfigDir + "/" + fileName;

        fs.copyFile(oldPath, newPath, (err) => {
            if (err) throw err;
        });

        console.log(`Copied '${oldPath}' to '${newPath}'`);
    }

    for (const config of configs) {
        const newConfigPath = outConfigDir + "/" + config.split("/").at(-1);
        fs.copyFile(config, newConfigPath, (err) => {
            if (err) throw err;
        });
        console.log(`Copied '${config}' to '${newConfigPath}'`);
    }

    fs.copySync(typeChain, outRoot + "/typechain-types");
    console.log(`Copied ${typeChain} to ${outRoot}`);

    console.log("Util: Copied files");
}

if (require.main === module) main();
