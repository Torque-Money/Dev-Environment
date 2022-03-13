import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";

import {ERC20Upgradeable, LPool, MarginLong, OracleTest} from "../../typechain-types";
import {addCollateral, allowedBorrowAmount, minCollateralAmount, removeCollateral} from "../../scripts/utils/helpers/utilMarginLong";
import {setPrice} from "../../scripts/utils/helpers/utilOracle";
import {provideLiquidity, redeemLiquidity} from "../../scripts/utils/helpers/utilPool";
import {shouldFail} from "../../scripts/utils/helpers/utilTest";
import {getCollateralTokens, getBorrowTokens, getTokenAmount} from "../../scripts/utils/helpers/utilTokens";
import {chooseConfig} from "../../scripts/utils/utilConfig";
import getConfigType from "../../scripts/utils/utilConfigTypeSelector";
import {BIG_NUM, BORROW_PRICE} from "../../scripts/utils/utilConstants";

describe("Interaction: MarginLong", () => {
    const configType = getConfigType(hre);
    const config = chooseConfig(configType);

    let poolTokens: ERC20Upgradeable[];
    let collateralTokens: ERC20Upgradeable[];

    let provideAmounts: BigNumber[];
    let collateralAmounts: BigNumber[];

    let oracle: OracleTest;
    let marginLong: MarginLong;
    let pool: LPool;

    let signerAddress: string;

    before(async () => {
        poolTokens = await getBorrowTokens(configType, hre);
        collateralTokens = await getCollateralTokens(configType, hre);

        marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress);
        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
        oracle = await hre.ethers.getContractAt("OracleTest", config.contracts.oracleAddress);

        provideAmounts = await getTokenAmount(hre, poolTokens);

        collateralAmounts = [];
        for (const token of collateralTokens) collateralAmounts.push(await minCollateralAmount(marginLong, oracle, token));

        signerAddress = await hre.ethers.provider.getSigner().getAddress();
    });

    beforeEach(async () => {
        provideLiquidity(pool, poolTokens, provideAmounts);
    });

    afterEach(async () => {
        await redeemLiquidity(configType, hre, pool);
    });

    it("deposit and undeposit collateral into the account", async () => {
        const index = 0;
        const collateralToken = collateralTokens[index];
        const collateralAmount = collateralAmounts[index];

        const initialBalance = await collateralToken.balanceOf(signerAddress);
        const initialMarginLongBalance = await collateralToken.balanceOf(marginLong.address);
        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        expect(await collateralToken.balanceOf(signerAddress)).to.equal(initialBalance.sub(collateralAmount));
        expect(await marginLong.collateral(collateralToken.address, signerAddress)).to.equal(collateralAmount);

        expect(await marginLong.totalCollateral(collateralToken.address)).to.equal(collateralAmount);
        expect(await collateralToken.balanceOf(marginLong.address)).to.equal(collateralAmount.add(initialMarginLongBalance));

        await (await marginLong.removeCollateral(collateralToken.address, collateralAmount)).wait();

        expect(await collateralToken.balanceOf(signerAddress)).to.equal(initialBalance);
        expect(await marginLong.collateral(collateralToken.address, signerAddress)).to.equal(0);

        expect(await marginLong.totalCollateral(collateralToken.address)).to.equal(0);
        expect(await collateralToken.balanceOf(marginLong.address)).to.equal(initialMarginLongBalance);
    });

    it("should not allow bad method calls", async () => {
        const index = 0;
        const collateralToken = collateralTokens[index];

        shouldFail(async () => await marginLong.addCollateral(hre.ethers.constants.AddressZero, 0));

        shouldFail(async () => await marginLong.addCollateral(collateralToken.address, 0));

        shouldFail(async () => await marginLong.addCollateral(collateralToken.address, BIG_NUM));
        shouldFail(async () => await marginLong.removeCollateral(collateralToken.address, BIG_NUM));
    });

    it("should open and repay a leveraged position", async () => {
        const index = 0;
        const poolToken = poolTokens[index];
        const collateralToken = collateralTokens[index];
        const collateralAmount = await minCollateralAmount(marginLong, oracle, collateralToken);

        const initialLiquidity = await pool.liquidity(poolToken.address);
        const initialTotalAmountLocked = await pool.totalAmountLocked(poolToken.address);

        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        const borrowAmount = await allowedBorrowAmount(hre, marginLong, oracle, pool, poolToken);
        await (await marginLong.borrow(poolToken.address, borrowAmount)).wait();

        expect((await marginLong.getBorrowingAccounts()).length).to.equal(1);

        expect(await pool.liquidity(poolToken.address)).to.equal(initialLiquidity.sub(borrowAmount));
        expect((await pool.totalAmountLocked(poolToken.address)).gte(initialTotalAmountLocked)).to.equal(true);
        expect(await marginLong.totalBorrowed(poolToken.address)).to.equal(borrowAmount);
        expect(await marginLong.borrowed(poolToken.address, signerAddress)).to.equal(borrowAmount);

        await shouldFail(async () => await marginLong.removeCollateral(collateralToken.address, collateralAmount));

        await (await marginLong["repayAccount(address)"](poolToken.address)).wait();

        expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

        expect((await pool.liquidity(poolToken.address)).gt(initialLiquidity)).to.equal(true);
        expect((await pool.totalAmountLocked(poolToken.address)).gt(initialTotalAmountLocked)).to.equal(true);
        expect(await marginLong.totalBorrowed(poolToken.address)).to.equal(0);
        expect(await marginLong.borrowed(poolToken.address, signerAddress)).to.equal(0);

        await removeCollateral(configType, hre, marginLong);
    });

    it("should open and repay all leveraged positions", async () => {
        await addCollateral(marginLong, collateralTokens, collateralAmounts);

        for (let i = 0; i < poolTokens.length; i++) {
            const token = poolTokens[i];

            const borrowAmount = (await allowedBorrowAmount(hre, marginLong, oracle, pool, token)).div(poolTokens.length);
            await marginLong.borrow(token.address, borrowAmount);
        }

        expect((await marginLong.getBorrowingAccounts()).length).to.equal(1);

        await (await marginLong["repayAccount()"]()).wait();

        expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

        for (let i = 0; i < poolTokens.length; i++) {
            expect((await pool.liquidity(poolTokens[i].address)).gte(provideAmounts[i])).to.equal(true);
            expect((await pool.totalAmountLocked(poolTokens[i].address)).gte(provideAmounts[i])).to.equal(true);
        }

        for (const token of poolTokens) {
            expect(await marginLong.totalBorrowed(token.address)).to.equal(0);
            expect(await marginLong.borrowed(token.address, signerAddress)).to.equal(0);
        }

        await removeCollateral(configType, hre, marginLong);
    });

    it("should borrow against equity", async () => {
        const index = 0;
        const poolToken = poolTokens[index];
        const collateralToken = collateralTokens[index];
        const collateralAmount = await minCollateralAmount(marginLong, oracle, collateralToken);

        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        const borrowAmount = await allowedBorrowAmount(hre, marginLong, oracle, pool, poolToken);
        await (await marginLong.borrow(poolToken.address, borrowAmount)).wait();

        const [initialMarginLevelNumerator, initialMarginLevelDenominator] = await marginLong.marginLevel(signerAddress);

        await setPrice(oracle, poolToken, hre.ethers.BigNumber.from(BORROW_PRICE.mul(100)));

        const [currentMarginLevelNumerator, currentMarginLevelDenominator] = await marginLong.marginLevel(signerAddress);

        expect(currentMarginLevelNumerator.mul(initialMarginLevelDenominator).gt(initialMarginLevelNumerator.mul(currentMarginLevelDenominator))).to.equal(true);

        await (await marginLong["repayAccount(address)"](poolToken.address)).wait();
        await removeCollateral(configType, hre, marginLong);
    });

    it("should fail to redeem LP tokens when they are being used", async () => {
        const index = 0;
        const poolToken = poolTokens[index];
        const collateralToken = collateralTokens[index];
        const collateralAmount = await minCollateralAmount(marginLong, oracle, collateralToken);

        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        const borrowAmount = await allowedBorrowAmount(hre, marginLong, oracle, pool, poolToken);
        await (await marginLong.borrow(poolToken.address, borrowAmount)).wait();

        const lpToken = await hre.ethers.getContractAt("LPoolToken", await pool.LPFromPT(poolToken.address));
        await shouldFail(async () => await pool.redeemLiquidity(lpToken.address, await lpToken.balanceOf(signerAddress)));

        await (await marginLong["repayAccount(address)"](poolToken.address)).wait();
        await removeCollateral(configType, hre, marginLong);
    });
});
