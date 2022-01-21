import fs from "fs";

import tempConstructor from "../../temp.constructor.json";

export function saveTempConstructor(key: string, constructorConfig: any) {
    (tempConstructor as any)[key] = constructorConfig;
    fs.writeFileSync("temp.constructor.json", JSON.stringify(tempConstructor));
}
