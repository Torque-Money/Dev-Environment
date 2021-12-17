import { ethers, network } from "hardhat";
import config from "../config.json";
import VPool from "../artifacts/contracts/IVPool.sol/IVPool.json";
import Margin from "../artifacts/contracts/IMargin.sol/IMargin.json";
import { expect } from "chai";

describe("Borrow", async () => {
    it("should stake, deposit, borrow, repay, withdraw, unstake", async () => {
        // Set the time of the network to be at the start of the next hour
        const timeSeconds = Math.floor(Date.now() / 1000);
        const timeRemaining = 3600 - (timeSeconds % 3600);
        await network.provider.send("evm_increaseTime", [timeRemaining]);
        await network.provider.send("evm_mine");

        // Initialize the contracts
        const signer = ethers.provider.getSigner();
        const pool = new ethers.Contract(config.poolAddress, VPool.abi, signer);
        const margin = new ethers.Contract(config.marginAddress, Margin.abi, signer);

        // Stake into the pool and verify it was correct
        const periodId = await pool.currentPeriodId();
        const stakeAsset = config.approved[0];
        const stakeAmount = ethers.BigNumber.from(10).mul(ethers.BigNumber.from(10).pow(stakeAsset.decimals));
        await pool.stake(stakeAsset.address, stakeAmount, periodId);

        expect(await pool.getLiquidity(periodId)).to.equal(stakeAmount);
    });
});
