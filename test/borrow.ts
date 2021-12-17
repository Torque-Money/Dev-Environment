import { ethers, network } from "hardhat";
import config from "../config.json";
import VPool from "../artifacts/contracts/IVPool.sol/IVPool.json";
import Margin from "../artifacts/contracts/IMargin.sol/IMargin.json";
import { expect } from "chai";

describe("Borrow", async () => {
    it("should stake, deposit, borrow, repay, withdraw, unstake", async () => {
        // Initialize the contracts
        const signer = ethers.provider.getSigner();
        const pool = new ethers.Contract(config.poolAddress, VPool.abi, signer);
        const margin = new ethers.Contract(config.marginAddress, Margin.abi, signer);

        // Set the time of the network to be at the start of the next hour
        const blockNumber = ethers.provider.blockNumber;
        const timeStamp = (await ethers.provider.getBlock(blockNumber)).timestamp;
        const startTime = timeStamp - (timeStamp % 3600) + 3600;
        await network.provider.send("evm_setNextBlockTimestamp", [startTime]);
        await network.provider.send("evm_mine");

        // Stake into the pool and verify it was correct
        const periodId = await pool.currentPeriodId();
        const stakeAsset = config.approved[0];
        const stakeAmount = ethers.BigNumber.from(10).mul(ethers.BigNumber.from(10).pow(stakeAsset.decimals));
        await pool.stake(stakeAsset.address, stakeAmount, periodId);

        console.log(await pool.getLiquidity(stakeAsset.address, periodId));
    });
});
