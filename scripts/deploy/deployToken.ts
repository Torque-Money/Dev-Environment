import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType, saveConfig} from "../util/utilConfig";
import {saveTempConstructor} from "../util/utilVerify";
import {getImplementationAddress} from "@openzeppelin/upgrades-core";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    {
        const constructorArgs = {
            name: "TAU",
            symbol: "TAU",
        };

        const ReserveToken = await hre.ethers.getContractFactory("ReserveToken");
        const reserveToken = await hre.upgrades.deployProxy(ReserveToken, Object.values(constructorArgs));
        await reserveToken.deployed();

        config.reserveTokenAddress = reserveToken.address;
        config.reserveTokenLogicAddress = await getImplementationAddress(hre.ethers.provider, reserveToken.address);
        console.log(`Deployed: Reserve token proxy and token | ${reserveToken.address} ${config.reserveTokenLogicAddress}`);

        if (configType !== "fork") saveTempConstructor(config.reserveTokenLogicAddress, {});
    }

    {
        const constructorArgs = {
            name: "Wrapped TAU",
            symbol: "wTAU",
        };

        const WrappedReserveToken = await hre.ethers.getContractFactory("ReserveTokenWrapped");
        const wrappedReserveToken = await hre.upgrades.deployProxy(WrappedReserveToken, Object.values(constructorArgs));
        await wrappedReserveToken.deployed();

        config.wrappedReserveTokenAddress = wrappedReserveToken.address;
        config.wrappedReserveTokenLogicAddress = await getImplementationAddress(hre.ethers.provider, wrappedReserveToken.address);
        console.log(`Deployed: Reserve wrapped token proxy and wrapped token | ${wrappedReserveToken.address} ${config.wrappedReserveTokenLogicAddress}`);

        if (configType !== "fork") saveTempConstructor(config.wrappedReserveTokenLogicAddress, {});
    }

    saveConfig(config, configType);
}

// **** Now I need to set up the reserve treasury and the reserve
