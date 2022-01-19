import fs from "fs";

export default async function main() {
    const compiledContracts = process.cwd() + "/artifacts/contracts";
    const configs = [process.cwd() + "/config.main.json", process.cwd() + "/config.test.json", process.cwd() + "/config.fork.json"];
    const abis = ["LPool/LPool.sol/LPool.json", "MarginLong/MarginLong.sol/MarginLong.json", "Oracle/Oracle.sol/Oracle.json"];
    const outDir = process.cwd() + "/../Torque-Frontend/src/config";

    for (const abi of abis) {
        const oldPath = compiledContracts + "/" + abi;

        const fileName = abi.split("/").at(-1);
        const newPath = outDir + "/" + fileName;

        fs.copyFile(oldPath, newPath, (err) => {
            if (err) throw err;
        });

        console.log(`Moved '${oldPath}' to '${newPath}'`);
    }

    for (const config of configs) {
        const newConfigPath = outDir + "/" + config.split("/").at(-1);
        fs.copyFile(config, newConfigPath, (err) => {
            if (err) throw err;
        });
        console.log(`Moved '${config}' to '${newConfigPath}'`);
    }

    console.log("Util: Copied files");
}
