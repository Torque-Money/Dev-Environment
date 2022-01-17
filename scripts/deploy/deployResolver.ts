import hre from "hardhat";
import fs from "fs";
import config from "../../config.json";

export default async function main() {
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

    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
