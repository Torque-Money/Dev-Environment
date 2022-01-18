import hre from "hardhat";
import {chooseConfig, saveConfig} from "../util/chooseConfig";

export default async function main(test: boolean = false) {
    const config = chooseConfig(test);

    const constructorArgs = {
        router: config.routerAddress,
    };
    const Converter = await hre.ethers.getContractFactory("Converter");
    const converter = await Converter.deploy(...Object.values(constructorArgs));
    config.converterAddress = converter.address;
    console.log("Deployed: Converter");

    saveConfig(config, test);
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
