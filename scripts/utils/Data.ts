import fs from "fs";

type Address = string;

interface Proxy {
    proxy: Address;
    implementation: Address;
}

interface BeaconProxy {
    proxies: Address[];
    beacon: Address;
    implementation: Address;
}

interface Data {
    contracts: {
        multisig: Address;
        timelock: Address;
        TAU: Proxy;
        "VaultV1.0": BeaconProxy,
        "BeefyLPStrategyV1.0": BeaconProxy
        "BeefyLPStrategyV1.1": BeaconProxy
        "LensV1.0": BeaconProxy
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
