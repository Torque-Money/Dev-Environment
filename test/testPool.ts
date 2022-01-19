import {expect} from "chai";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/util/testUtils";
import {ERC20, LPool} from "../typechain-types";

describe("Pool", async function () {
    let pool: LPool;
    let token: ERC20;
    let lpToken: ERC20;
    let signerAddress: string;

    beforeEach(async () => {
        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        token = await ethers.getContractAt("ERC20", config.approved[1].address);

        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(token.address));

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();
    });

    it("should stake tokens for LP tokens and redeem for an equal amount", async () => {
        const initialBalance = await token.balanceOf(signerAddress);

        const tokensProvided = ethers.BigNumber.from(1000000);
        const providedValue = await pool.provideLiquidityValue(token.address, tokensProvided);
        await pool.provideLiquidity(token.address, tokensProvided);

        expect(await token.balanceOf(signerAddress)).to.equal(initialBalance.sub(tokensProvided));
        expect(await lpToken.balanceOf(signerAddress)).to.equal(tokensProvided);

        expect(await token.balanceOf(pool.address)).to.equal(tokensProvided);
        expect(await pool.liquidity(token.address)).to.equal(tokensProvided);
        expect(await pool.tvl(token.address)).to.equal(tokensProvided);

        expect(await pool.redeemLiquidityValue(lpToken.address, providedValue)).to.equal(tokensProvided);

        await pool.redeemLiquidity(lpToken.address, providedValue);

        expect(await lpToken.balanceOf(signerAddress)).to.equal(0);
        expect(await token.balanceOf(signerAddress)).to.equal(initialBalance);

        expect(await token.balanceOf(pool.address)).to.equal(0);
        expect(await pool.liquidity(token.address)).to.equal(0);
        expect(await pool.tvl(token.address)).to.equal(0);
    });

    it("should fail to stake incorrect tokens and invalid amounts", async () => {
        await shouldFail(async () => await pool.provideLiquidity(lpToken.address, 0));
        await shouldFail(async () => await pool.redeemLiquidity(token.address, 0));

        await shouldFail(async () => await pool.provideLiquidity(token.address, ethers.BigNumber.from(2).pow(255)));
        await shouldFail(async () => await pool.redeemLiquidity(lpToken.address, 0));
    });

    it("should fail to access out of bounds operations", async () => {
        await shouldFail(async () => await pool.deposit(token.address, 0));
        await shouldFail(async () => await pool.withdraw(token.address, 0));

        await shouldFail(async () => await pool.claim(token.address, 0));
        await shouldFail(async () => await pool.unclaim(token.address, 0));
    });
});
