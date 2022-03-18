import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType, saveConfig} from "../utils/config/utilConfig";
import {saveTempConstructor} from "./utils/utilVerify";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const LPoolToken = await hre.ethers.getContractFactory("LPoolToken");
    const beacon = await hre.upgrades.deployBeacon(LPoolToken);
    await beacon.deployed();

    config.tokens.lpTokens.beaconAddress = beacon.address;
    const implementation = await hre.upgrades.beacon.getImplementationAddress(beacon.address);
    console.log(`Deployed: Beacon, implementation | ${beacon.address}, ${implementation}`);

    const tokens = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.setup.leveragePool).slice(3)) {
        console.log(approved.address);
        const LPToken = await hre.upgrades.deployBeaconProxy(beacon, LPoolToken, [
            config.setup.lpToken.LPPrefixName + " " + approved.name,
            config.setup.lpToken.LPPrefixSymbol + approved.symbol,
        ]);
        await LPToken.deployed();

        tokens.push(LPToken.address);

        console.log(`Deployed: LPoolToken | ${LPToken.address}`);
    }
    config.tokens.lpTokens.tokens = tokens;

    if (configType !== "fork") saveTempConstructor(implementation, {});
    saveConfig(config, configType);
}
