import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, saveConfig} from "../util/chooseConfig";

export default async function main(test: boolean, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(test);

    const constructorArgs = {
        router: config.routerAddress,
    };

    const Converter = await hre.ethers.getContractFactory("Converter");
    const converter = await Converter.deploy(constructorArgs.router);
    config.converterAddress = converter.address;
    console.log("Deployed: Converter");

    saveConfig(config, test);
}
