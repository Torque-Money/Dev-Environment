import {HardhatRuntimeEnvironment} from "hardhat/types";
import fs from "fs";

const TEMP_CONSTRUCTOR_NAME = "temp.constructor.json";

// Load constructor data
export function loadTempConstructor() {
    if (fs.existsSync(TEMP_CONSTRUCTOR_NAME)) {
        const data = fs.readFileSync(TEMP_CONSTRUCTOR_NAME).toString();
        return JSON.parse(data);
    } else {
        return {};
    }
}

// Save constructor data
export function saveTempConstructor(address: string, constructorConfig: any) {
    const tempConstructor = loadTempConstructor();
    (tempConstructor as any)[address] = Object.values(constructorConfig).map((item: any) => (typeof item === "object" ? item : item.toString()));
    fs.writeFileSync(TEMP_CONSTRUCTOR_NAME, JSON.stringify(tempConstructor));
}

// Verify contracts from the constructor data
export async function verifyAll(hre: HardhatRuntimeEnvironment) {
    const tempConstructor = loadTempConstructor();
    const tempStorage = JSON.parse(JSON.stringify(tempConstructor));

    for (const [key, value] of Object.entries(tempConstructor)) {
        await hre.run("verify:verify", {address: key, constructorArguments: value});

        delete tempStorage[key];
        fs.writeFileSync(TEMP_CONSTRUCTOR_NAME, JSON.stringify(tempStorage));
    }

    fs.unlinkSync(TEMP_CONSTRUCTOR_NAME);
}
