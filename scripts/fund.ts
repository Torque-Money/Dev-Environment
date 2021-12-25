import hre from "hardhat";
import config from "../config.json";
import ERC20 from "@openzeppelin/contracts/build/contracts/ERC20.json";

export default async function main() {
    // Account to fund with tokens
    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    // Fund the accounts and approve pool and margin protocols to spend
    for (const approved of config.approved) {
        // Fund account with tokens
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [approved.whale],
        });
        const tokenSigner = await hre.ethers.getSigner(approved.whale);
        const token = new hre.ethers.Contract(approved.address, ERC20.abi, tokenSigner);

        const tokenBalance = await token.balanceOf(tokenSigner.address);
        await token.transfer(signerAddress, tokenBalance);

        console.log(`Transferred ${tokenBalance.toString()} of tokens with address ${approved.address} to ${signerAddress}`);
    }
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
