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

interface DataV2P0 {
    multisig: Address;
    timelock: Address;
    Vault: BeaconProxy;
    BeefyLPStrategy: BeaconProxy;
    Lens: BeaconProxy;
    VaultETHWrapper: Proxy;
}

interface DataV2P1 extends DataV2P0 {}

interface DataV2P2 extends DataV2P1 {
    LensController: Address[];
}

type DataVersion = "V2.0" | "V2.1" | "V2.2";

// Get the path of the data file
export function getDataPath(version: DataVersion) {
    if (version === "V2.0") return process.cwd() + "/data/dataV2.0.json";
    else if (version === "V2.1") return process.cwd() + "/data/dataV2.1.json";
    else if (version === "V2.2") return process.cwd() + "/data/dataV2.2.json";
    else throw new Error("Invalid version");
}

// Load the data
export function loadData(version: DataVersion = "V2.2"): DataV2P0 | DataV2P1 | DataV2P2 {
    const dataPath = getDataPath(version);
    const stringified = fs.readFileSync(dataPath).toString();

    const parsed = JSON.parse(stringified);

    if (version === "V2.0") return parsed as DataV2P0;
    else if (version === "V2.1") return parsed as DataV2P1;
    else if (version === "V2.2") return parsed as DataV2P2;
    else throw new Error("Invalid version");
}
