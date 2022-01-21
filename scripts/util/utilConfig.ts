import fs from "fs";

import mainConfig from "../../config.main.json";
import testConfig from "../../config.test.json";
import forkConfig from "../../config.fork.json";

import tempConstructor from "../../temp.constructor.json";

export type ConfigType = "main" | "test" | "fork";

export function chooseConfig(configType: ConfigType) {
    let config;
    if (configType === "main") config = mainConfig;
    else if (configType === "test") config = testConfig;
    else config = forkConfig;
    return config;
}

export function saveConfig(config: any, configType: ConfigType) {
    let configName;
    if (configType === "main") configName = "config.main.json";
    else if (configType === "test") configName = "config.test.json";
    else configName = "config.fork.json";
    fs.writeFileSync(configName, JSON.stringify(config));
}

export function saveTempConstructor(key: string, constructorConfig: any) {
    (tempConstructor as any)[key] = constructorConfig;
    fs.writeFileSync("temp.constructor.json", JSON.stringify(tempConstructor));
}
