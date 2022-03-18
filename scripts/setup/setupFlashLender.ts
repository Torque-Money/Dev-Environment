import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../utils/config/utilConfig";
import {getFilteredTokenAddresses} from "../utils/tokens/utilGetTokens";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const flashLender = await hre.ethers.getContractAt("FlashLender", config.contracts.flashLender);

    await (await flashLender.setPool(config.contracts.leveragePoolAddress)).wait();
    console.log("-- Set pool");

    const flashLenderApprovedTokens = getFilteredTokenAddresses(configType, "flashLender");
    const isApproved = Array(flashLenderApprovedTokens.length).fill(true);
    await (await flashLender.setApproved(flashLenderApprovedTokens, isApproved)).wait();
    console.log("-- Set approved flash lend tokens");

    console.log("Setup: FlashLender");
}
