import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";

import {ERC20Upgradeable, LPool} from "../../typechain-types";

import {chooseConfig} from "../../scripts/utils/config/utilConfig";
import getConfigType from "../../scripts/utils/config/utilConfigTypeSelector";
import {BIG_NUM} from "../../scripts/utils/testing/utilConstants";
import {shouldFail} from "../../scripts/utils/testing/utilTest";
import {getFilteredTokens} from "../../scripts/utils/tokens/utilGetTokens";
import {getTokenAmounts, LPFromPT} from "../../scripts/utils/tokens/utilTokens";

describe("Usability: Pool", () => {
    const configType = getConfigType(hre);
    const config = chooseConfig(configType);

    let poolTokens: ERC20Upgradeable[];

    let provideAmounts: BigNumber[];

    let pool: LPool;

    let signerAddress: string;

    before(async () => {
        signerAddress = await hre.ethers.provider.getSigner().getAddress();

        poolTokens = await getFilteredTokens(config, hre, "leveragePool");

        provideAmounts = await getTokenAmounts(signerAddress, poolTokens);

        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
    });

    it("should stake tokens for LP tokens and redeem for an equal amount", async () => {
        const index = 0;
        const poolToken = poolTokens[index];
        const provideAmount = provideAmounts[index];
        const lpToken = await LPFromPT(hre, pool, poolToken);

        const initialPoolBalance = await poolToken.balanceOf(pool.address);
        const initialLiquidity = await pool.liquidity(poolToken.address);
        const initialTotalAmountLocked = await pool.totalAmountLocked(poolToken.address);

        const initialBalance = await poolToken.balanceOf(signerAddress);

        const outTokens = await pool.provideLiquidityOutLPTokens(poolToken.address, provideAmount);
        await (await pool.provideLiquidity(poolToken.address, provideAmount)).wait();

        expect(await poolToken.balanceOf(signerAddress)).to.equal(initialBalance.sub(provideAmount));
        expect(await lpToken.balanceOf(signerAddress)).to.equal(provideAmount);

        expect(await poolToken.balanceOf(pool.address)).to.equal(provideAmount.add(initialPoolBalance));
        expect(await pool.liquidity(poolToken.address)).to.equal(provideAmount.add(initialLiquidity));
        expect(await pool.totalAmountLocked(poolToken.address)).to.equal(provideAmount.add(initialTotalAmountLocked));

        expect(await pool.redeemLiquidityOutPoolTokens(lpToken.address, outTokens)).to.equal(provideAmount);
        await (await pool.redeemLiquidity(lpToken.address, outTokens)).wait();

        expect(await lpToken.balanceOf(signerAddress)).to.equal(0);
        expect(await poolToken.balanceOf(signerAddress)).to.equal(initialBalance);

        expect(await poolToken.balanceOf(pool.address)).to.equal(initialPoolBalance);
        expect(await pool.liquidity(poolToken.address)).to.equal(initialLiquidity);
        expect(await pool.totalAmountLocked(poolToken.address)).to.equal(initialTotalAmountLocked);
    });

    it("should stake and redeem multiple tokens at the same time", async () => {
        const initialPoolBalance: BigNumber[] = [];
        const initialLiquidity: BigNumber[] = [];
        const initialTotalAmountLocked: BigNumber[] = [];

        const initialBalance: BigNumber[] = [];

        for (const token of poolTokens) {
            initialPoolBalance.push(await token.balanceOf(pool.address));
            initialLiquidity.push(await pool.liquidity(token.address));
            initialTotalAmountLocked.push(await pool.totalAmountLocked(token.address));

            initialBalance.push(await token.balanceOf(signerAddress));
        }

        const outTokens: BigNumber[] = [];
        for (let i = 0; i < poolTokens.length; i++) {
            const poolToken = poolTokens[i];
            const provideAmount = provideAmounts[i];
            const lpToken = await LPFromPT(hre, pool, poolToken);

            outTokens.push(await pool.provideLiquidityOutLPTokens(poolToken.address, provideAmount));
            await (await pool.provideLiquidity(poolToken.address, provideAmount)).wait();

            expect(await poolToken.balanceOf(signerAddress)).to.equal(initialBalance[i].sub(provideAmount));
            expect(await lpToken.balanceOf(signerAddress)).to.equal(outTokens[i]);

            expect(await poolToken.balanceOf(pool.address)).to.equal(provideAmount.add(initialPoolBalance[i]));
            expect(await pool.liquidity(poolToken.address)).to.equal(provideAmount.add(initialLiquidity[i]));
            expect(await pool.totalAmountLocked(poolToken.address)).to.equal(provideAmount.add(initialTotalAmountLocked[i]));
        }

        for (let i = 0; i < poolTokens.length; i++) {
            const poolToken = poolTokens[i];
            const provideAmount = provideAmounts[i];
            const lpToken = await LPFromPT(hre, pool, poolToken);

            expect(await pool.redeemLiquidityOutPoolTokens(lpToken.address, outTokens[i])).to.equal(provideAmount);
            await (await pool.redeemLiquidity(lpToken.address, outTokens[i])).wait();

            expect(await lpToken.balanceOf(signerAddress)).to.equal(0);
            expect(await poolToken.balanceOf(signerAddress)).to.equal(initialBalance[i]);

            expect(await poolToken.balanceOf(pool.address)).to.equal(initialPoolBalance[i]);
            expect(await pool.liquidity(poolToken.address)).to.equal(initialLiquidity[i]);
            expect(await pool.totalAmountLocked(poolToken.address)).to.equal(initialTotalAmountLocked[i]);
        }
    });

    it("should fail to stake incorrect tokens and invalid amounts", async () => {
        await shouldFail(async () => await pool.provideLiquidity(hre.ethers.constants.AddressZero, 1));
        await shouldFail(async () => await pool.redeemLiquidity(hre.ethers.constants.AddressZero, 1));

        const index = 0;
        const poolToken = poolTokens[index];
        const lpToken = await LPFromPT(hre, pool, poolToken);

        await shouldFail(async () => await pool.provideLiquidity(poolToken.address, 0));
        await shouldFail(async () => await pool.redeemLiquidity(lpToken.address, 0));

        await shouldFail(async () => await pool.provideLiquidity(poolToken.address, BIG_NUM));
        await shouldFail(async () => await pool.redeemLiquidity(lpToken.address, BIG_NUM));
    });

    it("should fail to access out of bounds operations", async () => {
        const index = 0;
        const poolToken = poolTokens[index];

        await shouldFail(async () => await pool.deposit(poolToken.address, 0));
        await shouldFail(async () => await pool.withdraw(poolToken.address, 0));

        await shouldFail(async () => await pool.claim(poolToken.address, 0));
        await shouldFail(async () => await pool.unclaim(poolToken.address, 0));
    });
});
