import hre from "hardhat";
import ERC20 from "@openzeppelin/contracts/build/contracts/ERC20.json";
import {chooseConfig} from "./chooseConfig";

export default async function main(test: boolean = false) {
    const config = chooseConfig(test);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    for (const approved of config.approved) {
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [approved.whale],
        });
        const tokenSigner = await hre.ethers.getSigner(approved.whale);
        const token = new hre.ethers.Contract(approved.address, ERC20.abi, tokenSigner);

        const tokenBalance = await token.balanceOf(tokenSigner.address);
        await token.transfer(signerAddress, tokenBalance);

        console.log(`Fund: Transferred ${tokenBalance.toString()} of tokens with address ${approved.address} to ${signerAddress}`);
    }
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
