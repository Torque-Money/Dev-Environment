import hre from "hardhat";
import fs from "fs";
import config from "../../config.json";

export default async function main() {
    const constructorArgs = {
        token: config.tokenAddress,
        oracle: config.oracleAddress,
    };
    const Reserve = await hre.ethers.getContractFactory("Reserve");
    const reserve = await Reserve.deploy(...Object.values(constructorArgs));
    config.reserveAddress = reserve.address;
    console.log("Deployed: Reserve");
    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
