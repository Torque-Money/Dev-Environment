import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../utils/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const flashLender = await hre.ethers.getContractAt("FlashLender", config.contracts.flashLender);

    await (await flashLender.setPool(config.contracts.leveragePoolAddress)).wait();

    const flashLenderApprovedTokens = config.tokens.approved.filter((approved) => approved.flashLender).map((approved) => approved.address);
    const isApproved = Array(flashLenderApprovedTokens.length).fill(true);
    await (await flashLender.setApproved(flashLenderApprovedTokens, isApproved)).wait();

    console.log("Setup: FlashLender");
}
