import fs from "fs";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import tempConstructor from "../../temp.constructor.json";

export function saveTempConstructor(key: string, constructorConfig: any) {
    (tempConstructor as any)[key] = constructorConfig;
    fs.writeFileSync("temp.constructor.json", JSON.stringify(tempConstructor));
}

export async function verifyAll(hre: HardhatRuntimeEnvironment) {
    // **** I need to save as an array + I need to convert to string first
    for (const [key, value] of Object.entries(tempConstructor)) await hre.run("verify:verify", {address: key, constructorArguments: value});
}
