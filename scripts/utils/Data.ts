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
        Vault: BeaconProxy;
        BeefyLPStrategy: BeaconProxy;
        Lens: BeaconProxy;
        VaultETHWrapper: Proxy;
    };
}

type DataVersion = "V2.0" | "V2.1";

// Get the path of the data file
export function getDataPath(version: DataVersion) {
    if (version === "V2.0") {
        return process.cwd() + "/data/dataV2.0.json";
    } else if (version === "V2.1") {
        return process.cwd() + "/data/dataV2.1.json";
    } else {
        throw new Error("Invalid data path");
    }
}

// Save the data
export function saveData(data: Data, version: DataVersion = "V2.1") {
    const dataPath = getDataPath(version);
    const stringified = JSON.stringify(data);

    fs.writeFileSync(dataPath, stringified);
}

// Load the data
export function loadData(version: DataVersion = "V2.1") {
    const dataPath = getDataPath(version);
    const stringified = fs.readFileSync(dataPath).toString();

    return JSON.parse(stringified) as Data;
}
