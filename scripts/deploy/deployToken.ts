import hre, {ethers} from "hardhat";
import fs from "fs";
import config from "../../config.json";

export default async function main() {
    const constructorArgs = {
        initialSupply: ethers.BigNumber.from(10).pow(18).mul(1000000000),
    };
    const Token = await hre.ethers.getContractFactory("Token");
    const token = await Token.deploy(...Object.values(constructorArgs));
    config.tokenAddress = token.address;
    console.log("Deployed: Governance token");

    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
