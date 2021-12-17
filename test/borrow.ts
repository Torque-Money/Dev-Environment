import { ethers, network } from "hardhat";
import config from "../config.json";
import VPool from "../artifacts/contracts/IVPool.sol/IVPool.json";
import Margin from "../artifacts/contracts/IMargin.sol/IMargin.json";
import { expect } from "chai";

describe("Borrow", async () => {
    it("should stake, deposit, borrow, repay, withdraw, unstake", async () => {
        // Initialize the contracts
        const signer = ethers.provider.getSigner();
        const signerAddress = await signer.getAddress();
        const pool = new ethers.Contract(config.poolAddress, VPool.abi, signer);
        const margin = new ethers.Contract(config.marginAddress, Margin.abi, signer);

        // Set the time of the network to be at the start of the next hour
        const blockNumber = ethers.provider.blockNumber;
        const timeStamp = (await ethers.provider.getBlock(blockNumber)).timestamp;
        const startTime = timeStamp - (timeStamp % 3600) + 3600;
        await network.provider.send("evm_setNextBlockTimestamp", [startTime]);
        await network.provider.send("evm_mine");

        const periodId = await pool.currentPeriodId();

        // Stake into the pool
        const stakeAsset = config.approved[0];
        const stakeAmount = ethers.BigNumber.from(10).mul(ethers.BigNumber.from(10).pow(stakeAsset.decimals));
        await pool.stake(stakeAsset.address, stakeAmount, periodId);

        expect(await pool.getLiquidity(stakeAsset.address, periodId)).to.equal(stakeAmount);

        // Deposit into the pool
        const depositAsset = config.approved[1];
        const depositAmount = ethers.BigNumber.from(10).mul(ethers.BigNumber.from(10).pow(stakeAsset.decimals));
        await margin.deposit(depositAsset.address, stakeAsset.address, depositAmount);

        expect(await margin.collateralOf(signerAddress, depositAsset.address, stakeAsset.address, periodId)).to.equal(depositAmount);

        // Borrow against the collateral

        // **** Dont forget to go forward in time to do this
        await margin.borrow(depositAsset.address, stakeAsset.address, stakeAmount);

        // **** Does it actually make sense to have a period id here ??? debt doesnt matter once the period ends
        expect(await margin.debtOf(signerAddress, depositAsset.address, stakeAsset.address, periodId));

        // Repay the debt

        // Withdraw collateral

        // Unstake
    });
});
