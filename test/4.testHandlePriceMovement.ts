import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";

import {ITaskTreasury, LPool, MarginLong, Resolver, Timelock, ERC20, OracleTest} from "../typechain-types";
import {BORROW_PRICE, COLLATERAL_PRICE, shouldFail} from "../scripts/utils/helpers/utilTest";
import {getCollateralTokens, getPoolTokens} from "../scripts/utils/helpers/utilTokens";
import {chooseConfig, ConfigType} from "../scripts/utils/utilConfig";
import {changePrice, setPrice} from "../scripts/utils/helpers/utilOracle";
import {provideLiquidity, redeemLiquidity} from "../scripts/utils/helpers/utilPool";
import {addCollateral, allowedBorrowAmount, minCollateralAmount, removeCollateral} from "../scripts/utils/helpers/utilMarginLong";

describe("Handle price movement", async function () {
    const configType: ConfigType = "fork";
    const config = chooseConfig(configType);

    let poolToken: ERC20;
    let collateralToken: ERC20;

    let provideAmount: BigNumber;
    let collateralAmount: BigNumber;

    let oracle: OracleTest;
    let pool: LPool;
    let marginLong: MarginLong;
    let timelock: Timelock;
    let resolver: Resolver;
    let taskTreasury: ITaskTreasury;

    let signerAddress: string;

    const MINOR_PRICE_CHANGE_PERCENT = 10;
    const MAJOR_PRICE_CHANGE_PERCENT = 50;

    this.beforeAll(async () => {
        poolToken = (await getPoolTokens(configType, hre))[0];
        collateralToken = (await getCollateralTokens(configType, hre))[0];

        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
        oracle = await hre.ethers.getContractAt("OracleTest", config.contracts.oracleAddress);
        marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress);
        timelock = await hre.ethers.getContractAt("Timelock", config.contracts.timelockAddress);
        resolver = await hre.ethers.getContractAt("Resolver", config.contracts.resolverAddress);
        taskTreasury = await hre.ethers.getContractAt("ITaskTreasury", config.setup.taskTreasury);

        collateralAmount = await minCollateralAmount(marginLong, oracle, collateralToken);

        signerAddress = await hre.ethers.provider.getSigner().getAddress();
    });

    this.beforeEach(async () => {
        await setPrice(oracle, poolToken, BORROW_PRICE);
        await setPrice(oracle, collateralToken, COLLATERAL_PRICE);

        await addCollateral(marginLong, [collateralToken], [collateralAmount]);

        provideAmount = await allowedBorrowAmount(hre, marginLong, oracle, poolToken);
        await provideLiquidity(pool, [poolToken], [provideAmount]);

        await marginLong.borrow(poolToken.address, provideAmount);
    });

    this.afterEach(async () => {
        await removeCollateral(configType, hre, marginLong);
        await redeemLiquidity(configType, hre, pool);
    });

    // it("should liquidate an account", async () => {
    //     expect(await marginLong.liquidatable(signerAddress)).to.equal(false);
    //     await shouldFail(async () => await marginLong.liquidateAccount(signerAddress));

    //     await changePrice(oracle, poolToken, (100 - MAJOR_PRICE_CHANGE_PERCENT) / 100);

    //     expect(await marginLong.liquidatable(signerAddress)).to.equal(true);
    //     await (await marginLong.liquidateAccount(signerAddress)).wait();
    //     expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

    //     expect((await pool.totalAmountLocked(poolToken.address)).gte(provideAmount)).to.equal(true);
    // });

    // it("should reset an account", async () => {
    //     expect(await marginLong.resettable(signerAddress)).to.equal(false);
    //     await shouldFail(async () => await marginLong.resetAccount(signerAddress));

    //     await changePrice(oracle, collateralToken, (100 - MAJOR_PRICE_CHANGE_PERCENT) / 100);

    //     expect(await marginLong.resettable(signerAddress)).to.equal(true);
    //     await (await marginLong.resetAccount(signerAddress)).wait();
    //     expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

    //     expect((await marginLong.collateral(collateralToken.address, signerAddress)).lt(collateralAmount)).to.equal(true);
    //     expect((await pool.totalAmountLocked(poolToken.address)).gt(provideAmount)).to.equal(true);
    // });

    // it("should update timelock balance with tax after liquidation", async () => {
    //     const timelockInitialBalance = await poolToken.balanceOf(timelock.address);

    //     await changePrice(oracle, poolToken, (100 - MAJOR_PRICE_CHANGE_PERCENT) / 100);

    //     await (await marginLong.liquidateAccount(signerAddress)).wait();

    //     expect((await poolToken.balanceOf(timelock.address)).gt(timelockInitialBalance)).to.equal(true);
    // });

    // it("should liquidate an account with the resolver", async () => {
    //     const [initialCanExecute, initialCallData] = await resolver.checkLiquidate();
    //     expect(initialCanExecute).to.equal(false);
    //     await shouldFail(async () => await hre.ethers.provider.getSigner().sendTransaction({to: resolver.address, data: initialCallData}));

    //     const ethAddress = await resolver.ethAddress();
    //     const initialCredits = await taskTreasury.userTokenBalance(signerAddress, ethAddress);

    //     await changePrice(oracle, poolToken, (100 - MAJOR_PRICE_CHANGE_PERCENT) / 100);

    //     const [canExecute, callData] = await resolver.checkLiquidate();
    //     expect(canExecute).to.equal(true);
    //     await hre.ethers.provider.getSigner().sendTransaction({to: resolver.address, data: callData});

    //     expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

    //     expect((await taskTreasury.userTokenBalance(signerAddress, ethAddress)).gt(initialCredits)).to.equal(true);
    // });

    // **** This one is still broken and needs fixing
    // it("should reset an account with the resolver", async () => {
    //     const [initialCanExecute, initialCallData] = await resolver.checkReset();
    //     expect(initialCanExecute).to.equal(false);
    //     await shouldFail(async () => await hre.ethers.provider.getSigner().sendTransaction({to: resolver.address, data: initialCallData}));

    //     const ethAddress = await resolver.ethAddress();
    //     const initialCredits = await taskTreasury.userTokenBalance(signerAddress, ethAddress);

    //     await changePrice(oracle, collateralToken, (100 - MAJOR_PRICE_CHANGE_PERCENT) / 100);

    //     const [canExecute, callData] = await resolver.checkReset();
    //     expect(canExecute).to.equal(true);
    //     await hre.ethers.provider.getSigner().sendTransaction({to: resolver.address, data: callData});

    //     expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

    //     expect((await taskTreasury.userTokenBalance(signerAddress, ethAddress)).gt(initialCredits)).to.equal(true);

    //     // **** We need to do some sort of calculation that can figure out the liquidation price OR the the reset price of the given assets
    // });

    it("should repay an account with profit", async () => {
        // **** Check that the amounts are actually updated ? - why is there actually LESS value than what there initially was ???? (broken param ???)

        const initialAccountPrice = await marginLong.collateralPrice(signerAddress);
        console.log(await marginLong.collateralPrice(signerAddress));
        console.log(await marginLong.borrowedPrice(signerAddress));

        await changePrice(oracle, poolToken, (100 + MINOR_PRICE_CHANGE_PERCENT) / 100);

        console.log(await marginLong.collateralPrice(signerAddress));
        console.log(await marginLong.borrowedPrice(signerAddress));

        await (await marginLong["repayAccount()"]()).wait();
        expect((await marginLong.collateralPrice(signerAddress)).gt(initialAccountPrice)).to.equal(true);

        expect((await pool.totalAmountLocked(poolToken.address)).lt(provideAmount)).to.equal(true);
    });

    // it("should repay an account with a loss", async () => {
    //     await changePrice(oracle, poolToken, (100 - MINOR_PRICE_CHANGE_PERCENT) / 100);

    //     const initialAccountPrice = await marginLong.collateralPrice(signerAddress);
    //     await (await marginLong["repayAccount()"]()).wait();
    //     expect((await marginLong.collateralPrice(signerAddress)).lt(initialAccountPrice)).to.equal(true);

    //     expect((await pool.totalAmountLocked(poolToken.address)).gt(provideAmount)).to.equal(true);
    // });

    // it("should liquidate an account that exceeds the leverage limit by its collateral falling in value", async () => {
    //     await marginLong["repayAccount()"]();

    //     await (await marginLong.borrow(poolToken.address, provideAmount)).wait();

    //     await changePrice(oracle, collateralToken, (100 - MAJOR_PRICE_CHANGE_PERCENT) / 100);

    //     await (await marginLong.liquidateAccount(signerAddress)).wait();
    // });
});
