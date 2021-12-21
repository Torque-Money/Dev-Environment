import { getContractAddress } from "ethers/lib/utils";
import hre from "hardhat";

export default async function getFutureAddress(stepsAhead: number) {
    // Deploy and setup pool contract + find the margin address before deployment
    const signer = hre.ethers.provider.getSigner();
    const transactionCount = await signer.getTransactionCount();
    return getContractAddress({
        from: await signer.getAddress(),
        nonce: transactionCount + stepsAhead,
    });
}
