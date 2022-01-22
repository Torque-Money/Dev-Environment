import {ethers} from "hardhat";
import config from "../config.test.json";

export default async function main() {
    const lPool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
    const token = await ethers.getContractAt("ERC20", config.approved[1].address);

    const lpToken = await ethers.getContractAt("ERC20", await lPool.LPFromPT(token.address));

    const signer = ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const lpFromPT = await lPool.LPFromPT(token.address);
    console.log(lpFromPT);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
