import { ethers, network } from "hardhat";

describe("Borrow", async () => {
    it("should stake, deposit, borrow, repay, withdraw, unstake", async () => {
        // Set the time of the network to be at the start of the next hour
        const timeSeconds = Math.floor(Date.now() / 1000);
        const timeRemaining = 3600 - (timeSeconds % 3600);
        await network.provider.send("evm_increaseTime", [timeRemaining]);
        await network.provider.send("evm_mine");
    });
});
