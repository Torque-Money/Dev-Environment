import hre from "hardhat";
import fs from "fs";
import config from "../../config.json";

export default async function main() {
    const constructorArgs = {
        router: config.routerAddress,
    };
    const Converter = await hre.ethers.getContractFactory("Converter");
    const converter = await Converter.deploy(...Object.values(constructorArgs));
    config.converterAddress = converter.address;
    console.log("Deployed: Converter");

    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
