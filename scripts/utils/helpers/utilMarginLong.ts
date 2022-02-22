import {HardhatRuntimeEnvironment} from "hardhat/types";
import {MarginLong} from "../../../typechain-types";
import {chooseConfig, ConfigType} from "../utilConfig";

export async function removeCollateral(configType: ConfigType, hre: HardhatRuntimeEnvironment, marginLong: MarginLong) {
    const config = chooseConfig(configType);

    const signerAddress = await hre.ethers.provider.getSigner().getAddress();

    for (const token of config.tokens.approved.filter((approved) => approved.marginLongCollateral)) {
        const available = await marginLong.collateral(token.address, signerAddress);
        if (available.gt(0)) await marginLong.removeCollateral(token.address, available);
    }
}
