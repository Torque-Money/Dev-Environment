import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import hre from "hardhat";
import {shouldFail} from "../scripts/utils/helpers/utilTest";
import {ITaskTreasury, LPool, MarginLong, IOracle, Resolver, Timelock} from "../typechain-types";
import {getMarginLongBorrowTokens, getMarginLongCollateralTokens, getPoolTokens, getTokenAmount, Token} from "../scripts/utils/helpers/utilTokens";
import {chooseConfig, ConfigType} from "../scripts/utils/utilConfig";
import {setPrice} from "../scripts/utils/helpers/utilOracle";
import {provideLiquidity, redeemLiquidity} from "../scripts/utils/helpers/utilPool";
import {addCollateral, borrow, removeCollateral} from "../scripts/utils/helpers/utilMarginLong";

describe("Handle price movement", async function () {
    const configType: ConfigType = "fork";
    const config = chooseConfig(configType);

    let poolTokens: Token[];
    let collateralTokens: Token[];
    let borrowTokens: Token[];

    let provideAmounts: BigNumber[];
    let collateralAmounts: BigNumber[];
    let borrowAmounts: BigNumber[];

    let oracle: IOracle;
    let pool: LPool;
    let marginLong: MarginLong;
    let timelock: Timelock;
    let resolver: Resolver;
    let taskTreasury: ITaskTreasury;

    let signerAddress: string;

    const initialPoolTokenPrice = hre.ethers.BigNumber.from(5);
    const initialCollateralTokenPrice = hre.ethers.BigNumber.from(1);

    this.beforeAll(async () => {
        poolTokens = await getPoolTokens(configType, hre);
        collateralTokens = await getMarginLongCollateralTokens(configType, hre);
        borrowTokens = await getMarginLongBorrowTokens(configType, hre);

        provideAmounts = await getTokenAmount(
            hre,
            poolTokens.map((token) => token.token)
        );
        collateralAmounts = await getTokenAmount(
            hre,
            collateralTokens.map((token) => token.token)
        );
        borrowAmounts = await getTokenAmount(
            hre,
            borrowTokens.map((token) => token.token)
        );

        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        oracle = await ethers.getContractAt("OracleTest", config.oracleAddress);
        marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);
        timelock = await ethers.getContractAt("Timelock", config.timelockAddress);
        resolver = await ethers.getContractAt("Resolver", config.resolverAddress);
        taskTreasury = await ethers.getContractAt("ITaskTreasury", config.taskTreasury);

        for (const token of poolTokens) await setPrice(oracle, token.token, initialPoolTokenPrice);
        for (const token of collateralTokens) await setPrice(oracle, token.token, initialCollateralTokenPrice);

        signerAddress = await ethers.provider.getSigner().getAddress();
    });

    beforeEach(async () => {
        await provideLiquidity(
            pool,
            poolTokens.map((token) => token.token),
            provideAmounts
        );

        await addCollateral(
            marginLong,
            collateralTokens.map((token) => token.token),
            collateralAmounts
        );

        await borrow(
            marginLong,
            borrowTokens.map((token) => token.token),
            borrowAmounts
        );
    });

    afterEach(async () => {
        try {
            await (await marginLong["repayAccount()"]()).wait();
        } catch {}

        await removeCollateral(configType, hre, marginLong);
        await redeemLiquidity(configType, hre, pool);
    });

    it("should liquidate an account", async () => {
        expect(await marginLong.liquidatable(signerAddress)).to.equal(false);
        await shouldFail(async () => await marginLong.liquidateAccount(signerAddress));

        const [leverageNumerator, leverageDenominator] = await marginLong.currentLeverage(signerAddress);
        const [maxLeverageNumerator, maxLeverageDenominator] = await marginLong.maxLeverage();
        const [priceChangeNumerator, priceChangeDenominator] = [
            maxLeverageNumerator.mul(leverageDenominator).sub(leverageNumerator.mul(maxLeverageDenominator)).add(1),
            leverageNumerator.mul(maxLeverageNumerator),
        ];
        (await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice.mul(priceChangeDenominator.sub(priceChangeNumerator)).div(priceChangeDenominator))).wait();

        expect(await marginLong.liquidatable(signerAddress)).to.equal(true);
        await (await marginLong.liquidateAccount(signerAddress)).wait();
        expect(await marginLong["isBorrowing(address)"](signerAddress)).to.equal(false);

        expect((await pool.tvl(borrowedToken.address)).gt(depositAmount)).to.equal(true);
    });

    it("should reset an account", async () => {
        expect(await marginLong.resettable(signerAddress)).to.equal(false);
        await shouldFail(async () => await marginLong.resetAccount(signerAddress));

        await (await oracle.setPrice(collateralToken.address, 1)).wait();

        expect(await marginLong.resettable(signerAddress)).to.equal(true);
        await (await marginLong.resetAccount(signerAddress)).wait();
        expect(await marginLong["isBorrowing(address)"](signerAddress)).to.equal(false);

        expect((await marginLong.collateral(collateralToken.address, signerAddress)).lt(collateralAmount)).to.equal(true);
        expect((await pool.tvl(borrowedToken.address)).gt(depositAmount)).to.equal(true);
    });

    it("should test the timelock tax", async () => {
        const [leverageNumerator, leverageDenominator] = await marginLong.currentLeverage(signerAddress);
        const [maxLeverageNumerator, maxLeverageDenominator] = await marginLong.maxLeverage();
        const [priceChangeNumerator, priceChangeDenominator] = [
            maxLeverageNumerator.mul(leverageDenominator).sub(leverageNumerator.mul(maxLeverageDenominator)).add(1),
            leverageNumerator.mul(maxLeverageNumerator),
        ];
        (await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice.mul(priceChangeDenominator.sub(priceChangeNumerator)).div(priceChangeDenominator))).wait();

        const timelockInitialBalance = await borrowedToken.balanceOf(timelock.address);

        expect(await marginLong.liquidatable(signerAddress)).to.equal(true);
        await (await marginLong.liquidateAccount(signerAddress)).wait();
        expect(await marginLong["isBorrowing(address)"](signerAddress)).to.equal(false);

        expect((await borrowedToken.balanceOf(timelock.address)).gt(timelockInitialBalance)).to.equal(true);

        const initialBalance = await borrowedToken.balanceOf(signerAddress);
        const claimAvailable = await timelock.taxClaimAvailable(borrowedToken.address);
        expect(claimAvailable.gt(0)).to.equal(true);
        await (await timelock.claimTax(borrowedToken.address)).wait();
        await shouldFail(async () => await timelock.claimTax(borrowedToken.address));
        expect((await borrowedToken.balanceOf(signerAddress)).sub(initialBalance)).to.equal(claimAvailable);
    });

    it("should liquidate an account with the resolver", async () => {
        const [initialCanExecute, initialCallData] = await resolver.checkLiquidate();
        expect(initialCanExecute).to.equal(false);
        await shouldFail(async () => await ethers.provider.getSigner().sendTransaction({to: resolver.address, data: initialCallData}));

        const ethAddress = await resolver.ethAddress();
        const initialCredits = await taskTreasury.userTokenBalance(signerAddress, ethAddress);

        const [leverageNumerator, leverageDenominator] = await marginLong.currentLeverage(signerAddress);
        const [maxLeverageNumerator, maxLeverageDenominator] = await marginLong.maxLeverage();
        const [priceChangeNumerator, priceChangeDenominator] = [
            maxLeverageNumerator.mul(leverageDenominator).sub(leverageNumerator.mul(maxLeverageDenominator)).add(1),
            leverageNumerator.mul(maxLeverageNumerator),
        ];
        (await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice.mul(priceChangeDenominator.sub(priceChangeNumerator)).div(priceChangeDenominator))).wait();

        const [canExecute, callData] = await resolver.checkLiquidate();
        expect(canExecute).to.equal(true);
        await ethers.provider.getSigner().sendTransaction({to: resolver.address, data: callData});

        expect(await marginLong["isBorrowing(address)"](signerAddress)).to.equal(false);

        expect((await taskTreasury.userTokenBalance(signerAddress, ethAddress)).gt(initialCredits)).to.equal(true);
    });

    it("should reset an account with the resolver", async () => {
        const [initialCanExecute, initialCallData] = await resolver.checkReset();
        expect(initialCanExecute).to.equal(false);
        await shouldFail(async () => await ethers.provider.getSigner().sendTransaction({to: resolver.address, data: initialCallData}));

        const ethAddress = await resolver.ethAddress();
        const initialCredits = await taskTreasury.userTokenBalance(signerAddress, ethAddress);

        await (await oracle.setPrice(collateralToken.address, ethers.BigNumber.from(10).pow(priceDecimals).div(3))).wait();

        const [canExecute, callData] = await resolver.checkReset();
        expect(canExecute).to.equal(true);
        await ethers.provider.getSigner().sendTransaction({to: resolver.address, data: callData});

        expect(await marginLong["isBorrowing(address)"](signerAddress)).to.equal(false);

        expect((await taskTreasury.userTokenBalance(signerAddress, ethAddress)).gt(initialCredits)).to.equal(true);
    });

    it("should repay an account with profit", async () => {
        await (await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice.mul(110).div(100))).wait();

        const initialAccountPrice = await marginLong.collateralPrice(signerAddress);
        await (await marginLong["repayAccount()"]()).wait();
        expect((await marginLong.collateralPrice(signerAddress)).gt(initialAccountPrice)).to.equal(true);

        expect((await pool.tvl(borrowedToken.address)).lt(depositAmount)).to.equal(true);
    });

    it("should repay an account with a loss", async () => {
        const [leverageNumerator, leverageDenominator] = await marginLong.currentLeverage(signerAddress);
        const [maxLeverageNumerator, maxLeverageDenominator] = await marginLong.maxLeverage();
        const [priceChangeNumerator, priceChangeDenominator] = [
            maxLeverageNumerator.mul(leverageDenominator).sub(leverageNumerator.mul(maxLeverageDenominator)).sub(1),
            leverageNumerator.mul(maxLeverageNumerator),
        ];
        (await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice.mul(priceChangeDenominator.sub(priceChangeNumerator)).div(priceChangeDenominator))).wait();

        const initialAccountPrice = await marginLong.collateralPrice(signerAddress);
        await (await marginLong["repayAccount()"]()).wait();
        expect((await marginLong.collateralPrice(signerAddress)).lt(initialAccountPrice)).to.equal(true);

        expect((await pool.tvl(borrowedToken.address)).gt(depositAmount)).to.equal(true);
    });

    it("should liquidate an account that exceeds the leverage limit by its collateral falling in value whilst being above min collateral price", async () => {
        await marginLong["repayAccount()"]();
        await (await oracle.setPrice(borrowedToken.address, ethers.BigNumber.from(10).pow(priceDecimals).mul(300))).wait();

        await (await marginLong.borrow(borrowedToken.address, borrowedAmount)).wait();

        await (await oracle.setPrice(collateralToken.address, ethers.BigNumber.from(10).pow(priceDecimals).div(10))).wait();

        await (await marginLong.liquidateAccount(signerAddress)).wait();
    });
});
