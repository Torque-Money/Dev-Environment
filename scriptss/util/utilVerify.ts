import fs from "fs";
import {HardhatRuntimeEnvironment} from "hardhat/types";

const TEMP_CONSTRUCTOR_NAME = "temp.constructor.json";

export function loadTempConstructor() {
    if (fs.existsSync(TEMP_CONSTRUCTOR_NAME)) {
        const data = fs.readFileSync(TEMP_CONSTRUCTOR_NAME).toString();
        return JSON.parse(data);
    } else {
        return {};
    }
}

export function saveTempConstructor(address: string, constructorConfig: any) {
    const tempConstructor = loadTempConstructor();
    (tempConstructor as any)[address] = Object.values(constructorConfig).map((item: any) => item.toString());
    fs.writeFileSync(TEMP_CONSTRUCTOR_NAME, JSON.stringify(tempConstructor));
}

export async function verifyAll(hre: HardhatRuntimeEnvironment) {
    const tempConstructor = loadTempConstructor();
    for (const [key, value] of Object.entries(tempConstructor)) await hre.run("verify:verify", {address: key, constructorArguments: value});
    fs.unlinkSync(TEMP_CONSTRUCTOR_NAME);
}
