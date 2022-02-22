import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../utils/utilConfig";
import {saveTempConstructor} from "../utils/utilVerify";
import {getBeaconAddress} from "@openzeppelin/upgrades-core";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const LPoolToken = await hre.ethers.getContractFactory("LPoolToken");
    const beacon = await hre.upgrades.deployBeacon(LPoolToken);
    await beacon.deployed();

    config.tokens.lpTokens.beaconAddress = beacon.address;
    const implementation = await beacon.implementation();
    console.log(`Deployed: Beacon, implementation | ${beacon.address}, ${implementation}`);

    const tokens = [];
    for (const approved of config.tokens.approved.filter((approved) => approved.leveragePool)) {
        const LPToken = await hre.upgrades.deployBeaconProxy(beacon, LPoolToken, [
            config.setup.LPPrefixName + " " + approved.name,
            config.setup.LPPrefixSymbol + approved.symbol,
        ]);
        await LPToken.deployed();

        tokens.push(LPToken.address);

        console.log(`Deployed: LPoolToken`);
    }
    config.tokens.lpTokens.tokens = tokens;

    if (configType !== "fork") saveTempConstructor(implementation, {});
    saveConfig(config, configType);
}
