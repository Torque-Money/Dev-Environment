import { ethers, network } from "hardhat";
import config from "../config.json";
import LPool from "../artifacts/contracts/LPool.sol/LPool.json";
import Margin from "../artifacts/contracts/Margin.sol/Margin.json";
import { expect } from "chai";
import resetTime from "../utils/resetTime";
import timeTravel from "../utils/timeTravel";

describe("Borrow", async () => {
    it("should stake, deposit, borrow, repay, withdraw, unstake", async () => {
        // Initialize the contracts
        const signer = ethers.provider.getSigner();
        const signerAddress = await signer.getAddress();
        const pool = new ethers.Contract(config.poolAddress, LPool.abi, signer);
        const margin = new ethers.Contract(config.marginAddress, Margin.abi, signer);

        // Set the time of the network to be at the start of the next hour
        await resetTime();
        const periodId = await pool.currentPeriodId();

        // Stake into the pool
        const stakeAsset = config.approved[0];
        const stakeAmount = ethers.BigNumber.from(10000).mul(ethers.BigNumber.from(10).pow(stakeAsset.decimals));
        await pool.stake(stakeAsset.address, stakeAmount, periodId);

        expect(await pool.liquidity(stakeAsset.address, periodId)).to.equal(stakeAmount);

        // Deposit into the pool
        const depositAsset = config.approved[1];
        const depositAmount = ethers.BigNumber.from(10000).mul(ethers.BigNumber.from(10).pow(stakeAsset.decimals));
        await margin.deposit(depositAsset.address, stakeAsset.address, depositAmount);

        expect(await margin.collateralOf(signerAddress, depositAsset.address, stakeAsset.address, periodId)).to.equal(depositAmount);

        // Borrow against the collateral
        await timeTravel(20);
        await margin.borrow(depositAsset.address, stakeAsset.address, stakeAmount);

        expect(await margin.debtOf(signerAddress, depositAsset.address, stakeAsset.address)).to.equal(stakeAmount);

        // Repay the debt
        await timeTravel(5);
        await margin.repay(signerAddress, depositAsset.address, stakeAsset.address, periodId);

        expect(await margin.debtOf(signerAddress, depositAsset.address, stakeAsset.address)).to.equal(0);

        // Withdraw collateral
        const remainingCollateral = await margin.collateralOf(signerAddress, depositAsset.address, stakeAsset.address, periodId);
        await margin.withdraw(depositAsset.address, stakeAsset.address, remainingCollateral, periodId);

        expect(await margin.collateralOf(signerAddress, depositAsset.address, stakeAsset.address, periodId)).to.equal(0);

        // Unstake
        await timeTravel(40);
        await pool.redeem(stakeAsset.address, stakeAmount, periodId);

        expect(await pool.liquidity(stakeAsset.address, periodId)).to.equal(0);
    });
});
