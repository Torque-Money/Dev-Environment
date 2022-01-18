import fs from "fs";

import mainConfig from "../../config.json";
import testConfig from "../../config.test.json";

export function chooseConfig(test: boolean) {
    let config;
    if (test) config = testConfig;
    else config = mainConfig;
    return config;
}

export function saveConfig(config: any, test: boolean) {
    let configName;
    if (test) configName = "config.test.json";
    else configName = "config.json";
    fs.writeFileSync(configName, JSON.stringify(config));
}
