import hre from "hardhat";
import {chooseConfig, saveConfig} from "../util/chooseConfig";

export default async function main(test: boolean = false) {
    const config = chooseConfig(test);

    const constructorArgs = {
        pokeMe: config.gelatoPokeMe,
        marginLong: config.marginLongAddress,
        pool: config.leveragePoolAddress,
        converter: config.converterAddress,
    };
    const Resolver = await hre.ethers.getContractFactory("Resolver");
    const resolver = await Resolver.deploy(...Object.values(constructorArgs));
    config.resolverAddress = resolver.address;
    console.log("Deployed: Resolver");

    saveConfig(config, test);
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
