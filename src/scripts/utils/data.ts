import fs from "fs";

interface Data {
    TAUInitialSupply: string;
}

export function getDataPath() {
    return process.cwd() + "../../../data/data.json";
}

export function saveData(data: Data) {
    const dataPath = getDataPath();
    const stringified = JSON.stringify(data);

    fs.writeFileSync(dataPath, stringified);
}

export function loadData() {
    const dataPath = getDataPath();
    const stringified = fs.readFileSync(dataPath).toString();

    return JSON.parse(stringified) as Data;
}
