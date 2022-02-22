import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/utils/helpers/utilTest";
import {getLPTokens, getPoolTokens, getTokenAmount, Token} from "../scripts/utils/helpers/utilTokens";
import {ERC20, LPool, LPoolToken} from "../typechain-types";

describe("Pool", async function () {
    let poolTokens: Token[];
    let lpTokens: LPoolToken[];
    let depositAmounts: BigNumber[];

    let pool: LPool;

    let signerAddress: string;

    beforeEach(async () => {
        poolTokens = await getPoolTokens("fork", hre);
        depositAmounts = await getTokenAmount(
            hre,
            poolTokens.map((token) => token.token)
        );

        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);

        lpTokens = await getLPTokens("fork", hre, pool);

        signerAddress = await hre.ethers.provider.getSigner().getAddress();
    });

    it("should stake tokens for LP tokens and redeem for an equal amount", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;
        const lpToken = lpTokens[index];
        const depositAmount = depositAmounts[index];

        const initialBalance = await poolToken.balanceOf(signerAddress);

        const providedValue = await pool.provideLiquidityOutLPTokens(poolToken.address, depositAmount);
        await (await pool.provideLiquidity(poolToken.address, depositAmount)).wait();

        expect(await poolToken.balanceOf(signerAddress)).to.equal(initialBalance.sub(depositAmount));
        expect(await lpToken.balanceOf(signerAddress)).to.equal(depositAmount);

        expect(await poolToken.balanceOf(pool.address)).to.equal(depositAmount);
        expect(await pool.liquidity(poolToken.address)).to.equal(depositAmount);
        expect(await pool.totalAmountLocked(poolToken.address)).to.equal(depositAmount);

        expect(await pool.redeemLiquidityOutPoolTokens(lpToken.address, providedValue)).to.equal(depositAmount);
        await (await pool.redeemLiquidity(lpToken.address, providedValue)).wait();

        expect(await lpToken.balanceOf(signerAddress)).to.equal(0);
        expect(await poolToken.balanceOf(signerAddress)).to.equal(initialBalance);

        expect(await poolToken.balanceOf(pool.address)).to.equal(0);
        expect(await pool.liquidity(poolToken.address)).to.equal(0);
        expect(await pool.totalAmountLocked(poolToken.address)).to.equal(0);
    });

    it("should fail to stake incorrect tokens and invalid amounts", async () => {
        await shouldFail(async () => await pool.provideLiquidity(hre.ethers.constants.AddressZero, 1));
        await shouldFail(async () => await pool.redeemLiquidity(hre.ethers.constants.AddressZero, 1));

        const index = 0;
        const poolToken = poolTokens[index].token;
        const lpToken = lpTokens[index];

        await shouldFail(async () => await pool.provideLiquidity(poolToken.address, hre.ethers.BigNumber.from(2).pow(255)));
        await shouldFail(async () => await pool.redeemLiquidity(lpToken.address, hre.ethers.BigNumber.from(2).pow(255)));
    });

    it("should fail to access out of bounds operations", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;

        await shouldFail(async () => await pool.deposit(poolToken.address, 0));
        await shouldFail(async () => await pool.withdraw(poolToken.address, 0));

        await shouldFail(async () => await pool.claim(poolToken.address, 0));
        await shouldFail(async () => await pool.unclaim(poolToken.address, 0));
    });
});
