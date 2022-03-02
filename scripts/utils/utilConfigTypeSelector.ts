import {HardhatRuntimeEnvironment} from "hardhat/types";
import {ConfigType} from "./utilConfig";

export default async function getConfigType(hre: HardhatRuntimeEnvironment) {
    const {chainId} = await hre.ethers.provider.getNetwork();
    const configType = mapChainIdToConfigType(chainId);

    return configType;
}

function mapChainIdToConfigType(chainId: number): ConfigType {
    if (chainId === 1337) return "test";
    else if (chainId === 4) return "test";
    else if (chainId === 4) return "main";
    else throw Error("Chain Id not supported");
}
