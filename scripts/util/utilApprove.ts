import hre from "hardhat";
import ERC20 from "@openzeppelin/contracts/build/contracts/ERC20.json";
import {chooseConfig} from "./chooseConfig";

export default async function main(test: boolean = false) {
    const config = chooseConfig(test);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    for (const approved of config.approved) {
        // Approve pools to use tokens
        const token = new hre.ethers.Contract(approved.address, ERC20.abi, signer);
        const tokenBalance = await token.balanceOf(signerAddress);

        await token.approve(config.leveragePoolAddress, tokenBalance);
        await token.approve(config.marginLongAddress, tokenBalance);

        console.log(`Approve: Approved contracts to spend ${tokenBalance.toString()} tokens with address ${approved.address}`);
    }
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
