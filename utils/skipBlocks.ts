import hre from "hardhat";

export default async function skipBlocks(blocks: number) {
    for (let i = 0; i < blocks; i++) await hre.network.provider.send("evm_mine");
}
