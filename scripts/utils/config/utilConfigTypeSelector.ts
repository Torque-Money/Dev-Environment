import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ConfigType} from "./utilConfig";
import {OVERRIDE_CONFIG_TYPE} from "./utilConfigConstants";

// Get the config type from the name unless overriden
export default function getConfigType(hre: HardhatRuntimeEnvironment) {
    const networkName = hre.network.name;
    const configType = mapNetworkToConfigType(networkName as any);

    return OVERRIDE_CONFIG_TYPE !== null ? OVERRIDE_CONFIG_TYPE : configType;
}

// Map a specific network to the given config type
function mapNetworkToConfigType(networkName: "localhost" | "testnet" | "mainnet"): ConfigType {
    if (networkName === "localhost") return "fork";
    else if (networkName === "testnet") return "test";
    else if (networkName === "mainnet") return "main";
    else throw Error("Network not supported");
}
