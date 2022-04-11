import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType, saveConfig} from "../utils/config/utilConfig";
import {saveTempConstructor} from "../utils/deployment/utilVerify";
import {getFilteredApproved} from "../utils/tokens/utilGetTokens";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    // Deploy beacon proxy
    const LPoolToken = await hre.ethers.getContractFactory("LPoolToken");
    const beacon = await hre.upgrades.deployBeacon(LPoolToken);
    await beacon.deployed();

    // Save beacon proxy in config
    config.tokens.lpTokens.beaconAddress = beacon.address;
    const implementation = await hre.upgrades.beacon.getImplementationAddress(beacon.address);
    console.log(`Deployed: Beacon, implementation | ${beacon.address}, ${implementation}`);

    // Deploy LP tokens from the beacon
    const tokens = [];
    for (const approved of getFilteredApproved(config, "leveragePool")) {
        const LPToken = await hre.upgrades.deployBeaconProxy(beacon, LPoolToken, [
            config.setup.lpToken.LPPrefixName + " " + approved.name,
            config.setup.lpToken.LPPrefixSymbol + approved.symbol,
        ]);
        await LPToken.deployed();

        tokens.push(LPToken.address);

        console.log(`Deployed: LPoolToken | ${LPToken.address}`);
    }

    // Save tokens in config
    config.tokens.lpTokens.tokens = tokens;

    if (configType !== "fork") saveTempConstructor(implementation, {});
    saveConfig(config, configType);
}
