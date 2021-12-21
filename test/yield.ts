import { ethers, network } from "hardhat";
import Token from "../artifacts/contracts/Token.sol/Token.json";
import LPool from "../artifacts/contracts/LPool.sol/LPool.json";
import config from "../config.json";
import { expect } from "chai";
import resetTime from "../utils/resetTime";
import timeTravel from "../utils/timeTravel";
import deployPool from "../scripts/deployPool";
import deployToken from "../scripts/deployToken";

describe("Yield", async () => {
    await deployPool();
    await deployToken();

    it("Should stake tokens, reap yield, unstake tokens", async () => {
        // ======== Initialize the contracts ========
        const signer = ethers.provider.getSigner();
        const signerAddress = await signer.getAddress();
        const token = new ethers.Contract(config.tokenAddress, Token.abi, signer);
        const pool = new ethers.Contract(config.poolAddress, LPool.abi, signer);

        const stakeAsset = config.approved[0];
        const stakeAmount = ethers.BigNumber.from(10).pow(18).mul(100);

        // ======== Set the time of the network to be at the start of the next hour ========
        await resetTime();
        const periodId = await pool.currentPeriodId();

        //======== Stake tokens ========
        await pool.stake(stakeAsset.address, stakeAmount, periodId);
        expect(await pool.liquidity(stakeAsset.address, periodId)).to.equal(stakeAmount);

        //======== Yield reward ========
        await timeTravel(20);

        const initialTokenBalance = await token.balanceOf(signerAddress);
        const yieldAmount = await token.currentYieldReward();
        await token.yield();
        expect(await token.balanceOf(signerAddress)).to.equal(initialTokenBalance.add(yieldAmount));

        let executed;
        try {
            await token.yield();
            executed = true;
        } catch {
            executed = false;
        }
        expect(executed).to.equal(false);

        //======== Unstake tokens reward ========
        await timeTravel(40);

        await pool.redeem(stakeAsset.address, stakeAmount, periodId);
        expect(await pool.liquidity(stakeAsset.address, periodId)).to.equal(0);
    });
});
