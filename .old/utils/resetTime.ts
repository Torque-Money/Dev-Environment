import hre from "hardhat";

export default async function resetTime() {
    await hre.network.provider.send("evm_mine");
    const blockNumber = hre.ethers.provider.blockNumber;
    const timeStamp = (await hre.ethers.provider.getBlock(blockNumber)).timestamp;
    const startTime = timeStamp - (timeStamp % 3600) + 3600;
    await hre.network.provider.send("evm_setNextBlockTimestamp", [startTime]);
    await hre.network.provider.send("evm_mine");
}
