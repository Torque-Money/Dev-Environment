import {HardhatRuntimeEnvironment} from "hardhat/types";

import {ConfigType} from "./utilConfig";
import {OVERRIDE_CONFIG_TYPE} from "./utilConstants";

export default function getConfigType(hre: HardhatRuntimeEnvironment) {
    const networkName = hre.network.name;
    const configType = mapNetworkToConfig(networkName);

    return OVERRIDE_CONFIG_TYPE !== null ? OVERRIDE_CONFIG_TYPE : configType;
}

function mapNetworkToConfig(networkName: string): ConfigType {
    if (networkName === "localhost") return "fork";
    else if (networkName === "testnet") return "test";
    else if (networkName === "mainnet") return "main";
    else throw Error("Network not supported");
}
