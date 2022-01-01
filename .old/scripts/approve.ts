import hre from "hardhat";
import config from "../config.json";
import ERC20 from "@openzeppelin/contracts/build/contracts/ERC20.json";

export default async function main() {
    // Account to fund with tokens
    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    // Fund the accounts and approve pool and margin protocols to spend
    for (const approved of config.approved) {
        // Approve pools to use tokens
        const token = new hre.ethers.Contract(approved.address, ERC20.abi, signer);
        const tokenBalance = await token.balanceOf(signerAddress);

        await token.approve(config.poolAddress, tokenBalance);
        await token.approve(config.marginAddress, tokenBalance);

        console.log(`Approved contracts to spend ${tokenBalance.toString()} tokens with address ${approved.address}`);
    }
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
