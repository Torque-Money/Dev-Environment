import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";

import {IOracle, LPool, MarginLong} from "../typechain-types";
import {addCollateral, borrow, removeCollateral} from "../scripts/utils/helpers/utilMarginLong";
import {setPrice} from "../scripts/utils/helpers/utilOracle";
import {provideLiquidity, redeemLiquidity} from "../scripts/utils/helpers/utilPool";
import {BIG_NUM, shouldFail} from "../scripts/utils/helpers/utilTest";
import {getCollateralTokens, getPoolTokens, getTokenAmount, Token} from "../scripts/utils/helpers/utilTokens";
import {chooseConfig, ConfigType} from "../scripts/utils/utilConfig";

describe("MarginLong", async function () {
    const configType: ConfigType = "fork";
    const config = chooseConfig(configType);

    let poolTokens: Token[];
    let collateralTokens: Token[];

    let provideAmounts: BigNumber[];
    let collateralAmounts: BigNumber[];

    let oracle: IOracle;
    let marginLong: MarginLong;
    let pool: LPool;

    let signerAddress: string;

    const initialPoolTokenPrice = hre.ethers.BigNumber.from(1);
    const initialCollateralTokenPrice = hre.ethers.BigNumber.from(30);

    this.beforeAll(async () => {
        poolTokens = await getPoolTokens(configType, hre);
        collateralTokens = await getCollateralTokens(configType, hre);

        provideAmounts = await getTokenAmount(
            hre,
            poolTokens.map((token) => token.token)
        );
        collateralAmounts = await getTokenAmount(
            hre,
            collateralTokens.map((token) => token.token)
        );

        marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress);
        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
        oracle = await hre.ethers.getContractAt("IOracle", config.contracts.oracleAddress);

        signerAddress = await hre.ethers.provider.getSigner().getAddress();
    });

    this.beforeEach(async () => {
        for (const token of poolTokens.map((token) => token.token)) await setPrice(oracle, token, initialPoolTokenPrice);
        for (const token of collateralTokens.map((token) => token.token)) await setPrice(oracle, token, initialCollateralTokenPrice);

        provideLiquidity(
            pool,
            poolTokens.map((token) => token.token),
            provideAmounts
        );
    });

    this.afterEach(async () => {
        await redeemLiquidity(configType, hre, pool);
    });

    it("deposit and undeposit collateral into the account", async () => {
        const index = 0;
        const collateralToken = collateralTokens[index].token;
        const collateralAmount = collateralAmounts[index];

        const initialBalance = await collateralToken.balanceOf(signerAddress);
        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        expect(await collateralToken.balanceOf(signerAddress)).to.equal(initialBalance.sub(collateralAmount));
        expect(await marginLong.collateral(collateralToken.address, signerAddress)).to.equal(collateralAmount);

        expect(await marginLong.totalCollateral(collateralToken.address)).to.equal(collateralAmount);
        expect(await collateralToken.balanceOf(marginLong.address)).to.equal(collateralAmount);

        await (await marginLong.removeCollateral(collateralToken.address, collateralAmount)).wait();

        expect(await collateralToken.balanceOf(signerAddress)).to.equal(initialBalance);
        expect(await marginLong.collateral(collateralToken.address, signerAddress)).to.equal(0);

        expect(await marginLong.totalCollateral(collateralToken.address)).to.equal(0);
        expect(await collateralToken.balanceOf(marginLong.address)).to.equal(0);
    });

    it("should not allow bad deposits", async () => {
        const index = 0;
        const collateralToken = collateralTokens[index].token;

        shouldFail(async () => await marginLong.addCollateral(hre.ethers.constants.AddressZero, 0));

        shouldFail(async () => await marginLong.addCollateral(collateralToken.address, 0));

        shouldFail(async () => await marginLong.addCollateral(collateralToken.address, BIG_NUM));
        shouldFail(async () => await marginLong.removeCollateral(collateralToken.address, BIG_NUM));
    });

    it("should prevent bad leverage positions", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;
        const collateralToken = collateralTokens[index].token;
        const provideAmount = provideAmounts[index];
        const collateralAmount = collateralAmounts[index];

        await shouldFail(async () => await marginLong.borrow(poolToken.address, hre.ethers.BigNumber.from(2).pow(255)));

        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        await shouldFail(async () => await marginLong.borrow(poolToken.address, hre.ethers.BigNumber.from(2).pow(255)));

        await shouldFail(async () => await marginLong.borrow(poolToken.address, BIG_NUM));
        await setPrice(oracle, poolToken, hre.ethers.BigNumber.from(BIG_NUM));
        await shouldFail(async () => await marginLong.borrow(poolToken.address, provideAmount));

        await removeCollateral(configType, hre, marginLong);
    });

    it("should open and repay a leveraged position", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;
        const collateralToken = collateralTokens[index].token;
        const provideAmount = provideAmounts[index];
        const collateralAmount = collateralAmounts[index];

        const initialLiquidity = await pool.liquidity(poolToken.address);
        const initialTotalAmountLocked = await pool.totalAmountLocked(poolToken.address);

        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();
        await (await marginLong.borrow(poolToken.address, provideAmount)).wait();

        expect((await marginLong.getBorrowingAccounts()).length).to.not.equal(0);

        expect(await pool.liquidity(poolToken.address)).to.equal(initialLiquidity.sub(provideAmount));
        expect(await marginLong.totalBorrowed(poolToken.address)).to.equal(provideAmount);
        expect(await marginLong.borrowed(poolToken.address, signerAddress)).to.equal(provideAmount);

        await shouldFail(async () => await marginLong.removeCollateral(collateralToken.address, collateralValue));

        await (await marginLong["repayAccount(address)"](poolToken.address)).wait();

        expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

        const collateralValue = await marginLong.collateral(collateralToken.address, signerAddress);
        await (await marginLong.removeCollateral(collateralToken.address, collateralValue)).wait();

        expect((await pool.liquidity(poolToken.address)).gte(initialLiquidity)).to.equal(true);
        expect((await pool.totalAmountLocked(poolToken.address)).gte(initialTotalAmountLocked)).to.equal(true);
        expect(await marginLong.totalBorrowed(poolToken.address)).to.equal(0);
        expect(await marginLong.borrowed(poolToken.address, signerAddress)).to.equal(0);
    });

    it("should open and repay all leveraged positions", async () => {
        await addCollateral(
            marginLong,
            collateralTokens.map((token) => token.token),
            collateralAmounts
        );

        await borrow(
            marginLong,
            poolTokens.map((token) => token.token),
            provideAmounts
        );

        expect((await marginLong.getBorrowingAccounts()).length).to.equal(1);

        await (await marginLong["repayAccount()"]()).wait();

        expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

        for (let i = 0; i < poolTokens.length; i++) {
            expect((await pool.liquidity(poolTokens[i].token.address)).gte(provideAmounts[i])).to.equal(true);
            expect((await pool.totalAmountLocked(poolTokens[i].token.address)).gte(provideAmounts[i])).to.equal(true);
        }

        for (const token of poolTokens) {
            expect(await marginLong.totalBorrowed(token.token.address)).to.equal(0);
            expect(await marginLong.borrowed(token.token.address, signerAddress)).to.equal(0);
        }

        await removeCollateral(configType, hre, marginLong);
    });

    it("should borrow against equity", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;
        const collateralToken = collateralTokens[index].token;
        const provideAmount = provideAmounts[index];
        const collateralAmount = collateralAmounts[index];

        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        await (await marginLong.borrow(poolToken.address, provideAmount)).wait();

        const [initialMarginLevelNumerator, initialMarginLevelDenominator] = await marginLong.marginLevel(signerAddress);

        await setPrice(oracle, poolToken, hre.ethers.BigNumber.from(3000));

        const [currentMarginLevelNumerator, currentMarginLevelDenominator] = await marginLong.marginLevel(signerAddress);

        expect(currentMarginLevelNumerator.mul(initialMarginLevelDenominator).gt(initialMarginLevelNumerator.mul(currentMarginLevelDenominator))).to.equal(true);

        await (await marginLong["repayAccount(address)"](poolToken.address)).wait();
        await removeCollateral(configType, hre, marginLong);
    });

    it("should fail to redeem LP tokens when they are being used", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;
        const collateralToken = collateralTokens[index].token;
        const provideAmount = provideAmounts[index];
        const collateralAmount = collateralAmounts[index];

        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        await (await marginLong.borrow(poolToken.address, provideAmount)).wait();

        const lpToken = await hre.ethers.getContractAt("LPoolToken", await pool.LPFromPT(poolToken.address));
        await shouldFail(async () => await pool.redeemLiquidity(lpToken.address, await lpToken.balanceOf(signerAddress)));

        await (await marginLong["repayAccount(address)"](poolToken.address)).wait();
        await removeCollateral(configType, hre, marginLong);
    });
});
