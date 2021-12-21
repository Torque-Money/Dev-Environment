import { ethers } from "ethers";
import { getContractAddress } from "ethers/lib/utils";

export default async function getFutureAddress(signer: ethers.providers.JsonRpcSigner, stepsAhead: number) {
    // Deploy and setup pool contract + find the margin address before deployment
    const transactionCount = await signer.getTransactionCount();
    return getContractAddress({
        from: await signer.getAddress(),
        nonce: transactionCount + stepsAhead,
    });
}
