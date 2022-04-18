import fs from "fs";

interface Proxy {
    proxy: string;
    implementation: string;
}

interface BeaconProxy {
    proxies: Proxy[];
    beacon: string;
}

interface Data {
    contracts: {
        multisig: string;
        timelock: string;
        TAU: Proxy;
    };
}

// Get the path of the data file
export function getDataPath() {
    return process.cwd() + "/data/data.json";
}

// Save the data
export function saveData(data: Data) {
    const dataPath = getDataPath();
    const stringified = JSON.stringify(data);

    fs.writeFileSync(dataPath, stringified);
}

// Load the data
export function loadData() {
    const dataPath = getDataPath();
    const stringified = fs.readFileSync(dataPath).toString();

    return JSON.parse(stringified) as Data;
}
