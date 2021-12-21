import { ethers, network } from "hardhat";
import ERC20Votes from "@openzeppelin/contracts/build/contracts/ERC20Votes.json";
import LPool from "../artifacts/contracts/LPool.sol/LPool.json";
import config from "../config.json";
import { expect } from "chai";

describe("Yield", async () => {
    it("Should stake tokens, reap yield, unstake tokens", async () => {
        // ======== Initialize the contracts ========
        const signer = ethers.provider.getSigner();
        const signerAddress = await signer.getAddress();
        const token = new ethers.Contract(config.tokenAddress, ERC20Votes.abi, signer);
        const pool = new ethers.Contract(config.poolAddress, LPool.abi, signer);

        const stakeAsset = config.approved[0];
        const stakeAmount = ethers.BigNumber.from(10).pow(18).mul(100);

        const periodId = await pool.currentPeriodId();

        // ======== Set the time of the network to be at the start of the next hour ========
        const blockNumber = ethers.provider.blockNumber;
        const timeStamp = (await ethers.provider.getBlock(blockNumber)).timestamp;
        const startTime = timeStamp - (timeStamp % 3600) + 3600;
        await network.provider.send("evm_setNextBlockTimestamp", [startTime]);
        await network.provider.send("evm_mine");

        //======== Stake tokens ========
        await pool.stake(stakeAsset.address, stakeAmount, periodId);
        expect(await pool.liquidity(stakeAsset.address, periodId)).to.equal(stakeAmount);

        //======== Yield reward ========
        await network.provider.send("evm_increaseTime", [20 * 60]);
        await network.provider.send("evm_mine");

        await token.yield();

        //======== Unstake tokens reward ========
    });
});
