import fs from "fs";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import tempConstructor from "../../temp.constructor.json";
import {chooseConfig, ConfigType} from "./utilConfig";

export function saveTempConstructor(key: string, constructorConfig: any) {
    (tempConstructor as any)[key] = constructorConfig;
    fs.writeFileSync("temp.constructor.json", JSON.stringify(tempConstructor));
}

export function verifyAll(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);
}
