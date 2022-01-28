import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/util/utilsTest";
import {ERC20, LPool} from "../typechain-types";

describe("Pool", async function () {
    let approvedToken: any;
    let token: ERC20;

    let lpToken: ERC20;

    let pool: LPool;

    let signerAddress: string;

    let depositAmount: BigNumber;

    beforeEach(async () => {
        approvedToken = config.approved[1];
        token = await ethers.getContractAt("ERC20", approvedToken.address);

        depositAmount = ethers.BigNumber.from(10).pow(approvedToken.decimals).mul(50);

        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);

        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(token.address));

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();
    });

    it("should stake tokens for LP tokens and redeem for an equal amount", async () => {
        const initialBalance = await token.balanceOf(signerAddress);

        const providedValue = await pool.addLiquidityOutLPTokens(token.address, depositAmount);
        await pool.addLiquidity(token.address, depositAmount);

        expect(await token.balanceOf(signerAddress)).to.equal(initialBalance.sub(depositAmount));
        expect(await lpToken.balanceOf(signerAddress)).to.equal(depositAmount);

        expect(await token.balanceOf(pool.address)).to.equal(depositAmount);
        expect(await pool.liquidity(token.address)).to.equal(depositAmount);
        expect(await pool.tvl(token.address)).to.equal(depositAmount);

        expect(await pool.removeLiquidityOutPoolTokens(lpToken.address, providedValue)).to.equal(depositAmount);

        await pool.removeLiquidity(lpToken.address, providedValue);

        expect(await lpToken.balanceOf(signerAddress)).to.equal(0);
        expect(await token.balanceOf(signerAddress)).to.equal(initialBalance);

        expect(await token.balanceOf(pool.address)).to.equal(0);
        expect(await pool.liquidity(token.address)).to.equal(0);
        expect(await pool.tvl(token.address)).to.equal(0);
    });

    it("should fail to stake incorrect tokens and invalid amounts", async () => {
        await shouldFail(async () => await pool.addLiquidity(lpToken.address, 0));
        await shouldFail(async () => await pool.removeLiquidity(lpToken.address, 0));

        await shouldFail(async () => await pool.addLiquidity(token.address, ethers.BigNumber.from(2).pow(255)));
        await shouldFail(async () => await pool.removeLiquidity(token.address, 0));
    });

    it("should fail to access out of bounds operations", async () => {
        await shouldFail(async () => await pool.deposit(token.address, 0));
        await shouldFail(async () => await pool.withdraw(token.address, 0));

        await shouldFail(async () => await pool.claim(token.address, 0));
        await shouldFail(async () => await pool.unclaim(token.address, 0));
    });
});
