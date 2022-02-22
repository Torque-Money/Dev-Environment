import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";
import {removeCollateral} from "../scripts/utils/helpers/utilMarginLong";
import {setPrice} from "../scripts/utils/helpers/utilOracle";
import {provideLiquidity, redeemLiquidity} from "../scripts/utils/helpers/utilPool";
import {BIG_NUM, shouldFail} from "../scripts/utils/helpers/utilTest";
import {getMarginLongBorrowTokens, getMarginLongCollateralTokens, getPoolTokens, getTokenAmount, Token} from "../scripts/utils/helpers/utilTokens";
import {chooseConfig, ConfigType} from "../scripts/utils/utilConfig";
import {IOracle, LPool, MarginLong} from "../typechain-types";

describe("MarginLong", async function () {
    const configType: ConfigType = "fork";
    const config = chooseConfig(configType);

    let depositTokens: Token[];
    let collateralTokens: Token[];
    let borrowTokens: Token[];

    let depositAmounts: BigNumber[];
    let collateralAmounts: BigNumber[];
    let borrowAmounts: BigNumber[];

    let oracle: IOracle;
    let marginLong: MarginLong;
    let pool: LPool;

    let signerAddress: string;

    this.beforeAll(async () => {
        depositTokens = await getPoolTokens(configType, hre);
        collateralTokens = await getMarginLongCollateralTokens(configType, hre);
        borrowTokens = await getMarginLongBorrowTokens(configType, hre);

        depositAmounts = await getTokenAmount(
            hre,
            depositTokens.map((token) => token.token)
        );
        collateralAmounts = await getTokenAmount(
            hre,
            depositTokens.map((token) => token.token)
        );
        borrowAmounts = await getTokenAmount(
            hre,
            borrowTokens.map((token) => token.token)
        );

        marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress);
        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
        oracle = await hre.ethers.getContractAt("IOracle", config.contracts.oracleAddress);

        signerAddress = await hre.ethers.provider.getSigner().getAddress();
    });

    this.beforeEach(async () => {
        for (const token of [...depositTokens, ...collateralTokens, ...borrowTokens].map((token) => token.token))
            await setPrice(oracle, token, hre.ethers.BigNumber.from(1));

        provideLiquidity(
            pool,
            depositTokens.map((token) => token.token),
            depositAmounts
        );
    });

    this.afterEach(async () => {
        redeemLiquidity(configType, hre, pool);
    });

    // **** Add a test here to test the same deposit at the same time

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
        const collateralToken = collateralTokens[index].token;
        const borrowToken = borrowTokens[index].token;
        const collateralAmount = collateralAmounts[index];
        const borrowAmount = borrowAmounts[index];

        await shouldFail(async () => await marginLong.borrow(borrowToken.address, hre.ethers.BigNumber.from(2).pow(255)));

        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        await shouldFail(async () => await marginLong.borrow(borrowToken.address, hre.ethers.BigNumber.from(2).pow(255)));

        await shouldFail(async () => await marginLong.borrow(borrowToken.address, BIG_NUM));
        await setPrice(oracle, borrowToken, hre.ethers.BigNumber.from(BIG_NUM));
        await shouldFail(async () => await marginLong.borrow(borrowToken.address, borrowAmount));

        await removeCollateral("fork", hre, marginLong);
    });

    it("should open and repay a leveraged position", async () => {
        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();
        await (await marginLong.borrow(borrowedToken.address, borrowedAmount)).wait();

        expect((await marginLong.getBorrowingAccounts()).length).to.not.equal(0);

        expect(await pool.liquidity(borrowedToken.address)).to.equal(depositAmount.sub(borrowedAmount));
        expect(await marginLong.totalBorrowed(borrowedToken.address)).to.equal(borrowedAmount);
        expect(await marginLong.borrowed(borrowedToken.address, signerAddress)).to.equal(borrowedAmount);
        expect(await pool.claimed(borrowedToken.address, marginLong.address)).to.equal(borrowedAmount);

        await shouldFail(async () => await marginLong.removeCollateral(collateralToken.address, collateralValue));

        await (await marginLong["repayAccount(address)"](borrowedToken.address)).wait();

        expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

        const collateralValue = await marginLong.collateral(collateralToken.address, signerAddress);
        await (await marginLong.removeCollateral(collateralToken.address, collateralValue)).wait();

        expect((await pool.liquidity(borrowedToken.address)).gte(depositAmount)).to.equal(true);
        expect((await pool.tvl(borrowedToken.address)).gte(depositAmount)).to.equal(true);
        expect(await marginLong.totalBorrowed(borrowedToken.address)).to.equal(0);
        expect(await marginLong.borrowed(borrowedToken.address, signerAddress)).to.equal(0);
        expect(await pool.claimed(borrowedToken.address, marginLong.address)).to.equal(0);
    });

    it("should open and repay all leveraged positions", async () => {
        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        await (await marginLong.borrow(borrowedToken.address, borrowedAmount)).wait();

        expect((await marginLong.getBorrowingAccounts()).length).to.not.equal(0);

        await (await marginLong["repayAccount()"]()).wait();

        expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

        const collateralValue = await marginLong.collateral(collateralToken.address, signerAddress);
        await (await marginLong.removeCollateral(collateralToken.address, collateralValue)).wait();

        expect((await pool.liquidity(borrowedToken.address)).gte(depositAmount)).to.equal(true);
        expect((await pool.tvl(borrowedToken.address)).gte(depositAmount)).to.equal(true);
        expect(await marginLong.totalBorrowed(borrowedToken.address)).to.equal(0);
        expect(await marginLong.borrowed(borrowedToken.address, signerAddress)).to.equal(0);
        expect(await pool.claimed(borrowedToken.address, marginLong.address)).to.equal(0);
    });

    it("should borrow against equity", async () => {
        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        await (await marginLong.borrow(borrowedToken.address, borrowedAmount)).wait();

        const [initialMarginLevelNumerator, initialMarginLevelDenominator] = await marginLong.marginLevel(signerAddress);

        await (await oracle.setPrice(borrowedToken.address, ethers.BigNumber.from(10).pow(priceDecimals).mul(3000))).wait();

        const [currentMarginLevelNumerator, currentMarginLevelDenominator] = await marginLong.marginLevel(signerAddress);

        expect(currentMarginLevelNumerator.mul(initialMarginLevelDenominator).gt(initialMarginLevelNumerator.mul(currentMarginLevelDenominator))).to.equal(true);

        await (await marginLong["repayAccount()"]()).wait();
        const potentialCollateralTokens = [collateralToken, borrowedToken];
        for (const token of potentialCollateralTokens) {
            const amount = await marginLong.collateral(token.address, signerAddress);
            if (amount.gt(0)) await (await marginLong.removeCollateral(token.address, amount)).wait();
        }
    });

    it("should fail to redeem LP tokens when they are being used", async () => {
        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        await (await marginLong.borrow(borrowedToken.address, borrowedAmount)).wait();

        await shouldFail(async () => await pool.removeLiquidity(lpToken.address, await lpToken.balanceOf(signerAddress)));

        await (await marginLong["repayAccount()"]()).wait();
        const potentialCollateralTokens = [collateralToken, borrowedToken];
        for (const token of potentialCollateralTokens) {
            const amount = await marginLong.collateral(token.address, signerAddress);
            if (amount.gt(0)) await (await marginLong.removeCollateral(token.address, amount)).wait();
        }
    });
});
