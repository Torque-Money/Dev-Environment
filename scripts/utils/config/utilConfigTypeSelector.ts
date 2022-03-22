import {config} from "hardhat";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ConfigType} from "./utilConfig";

// Get the config type to use
export default function getConfigType(hre: HardhatRuntimeEnvironment) {
    const networkName = hre.network.name;
    const configType = mapNetworkToConfigType(networkName as any);

    const configTypeOverride: ConfigType | undefined = (config as any).configTypeOverride;

    return configTypeOverride ? configTypeOverride : configType;
}

// Map a specific network to the given config type
function mapNetworkToConfigType(networkName: "localhost" | "testnet" | "mainnet"): ConfigType {
    if (networkName === "localhost") return "fork";
    else if (networkName === "testnet") return "test";
    else if (networkName === "mainnet") return "main";
    else throw Error("Network not supported");
}
