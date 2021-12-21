import hre from "hardhat";
import config from "../config.json";
import fs from "fs";

async function main() {
    await hre.run("compile");

    // Deploy and setup the oracle contract
    const oracleConfig = {
        decimals: (1e12).toString(),
    };
    const Oracle = await hre.ethers.getContractFactory("Oracle");
    const oracle = await Oracle.deploy(...Object.values(oracleConfig));
    await oracle.deployed();
    console.log(`Oracle deployed to ${oracle.address}`);
    config.oracleAddress = oracle.address;

    for (const address of config.routerAddresses) {
        await oracle.addRouter(address);
    }
    console.log("Added routers to Oracle");

    fs.writeFileSync("config.json", JSON.stringify(config));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
