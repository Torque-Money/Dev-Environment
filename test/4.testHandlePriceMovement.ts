import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/util/utilsTest";
import {ERC20, LPool, MarginLong, OracleTest, Resolver, Timelock} from "../typechain-types";

describe("Handle price movement", async function () {
    let collateralApproved: any;
    let collateralToken: ERC20;

    let borrowedApproved: any;
    let borrowedToken: ERC20;

    let lpToken: ERC20;

    let priceDecimals: BigNumber;
    let initialCollateralTokenPrice: BigNumber;
    let initialBorrowTokenPrice: BigNumber;

    let oracle: OracleTest;
    let pool: LPool;
    let marginLong: MarginLong;
    let timelock: Timelock;
    let resolver: Resolver;

    let signerAddress: string;

    let collateralAmount: BigNumber;
    let borrowedAmount: BigNumber;
    let depositAmount: BigNumber;

    beforeEach(async () => {
        collateralApproved = config.approved[0];
        collateralToken = await ethers.getContractAt("ERC20", collateralApproved.address);

        borrowedApproved = config.approved[1];
        borrowedToken = await ethers.getContractAt("ERC20", borrowedApproved.address);

        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        oracle = await ethers.getContractAt("OracleTest", config.oracleAddress);
        marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);
        timelock = await ethers.getContractAt("Timelock", config.timelockAddress);
        resolver = await ethers.getContractAt("Resolver", config.resolverAddress);

        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(borrowedToken.address));

        priceDecimals = await oracle.priceDecimals();
        initialCollateralTokenPrice = ethers.BigNumber.from(10).pow(priceDecimals);
        initialBorrowTokenPrice = ethers.BigNumber.from(10).pow(priceDecimals).mul(30);
        await (await oracle.setPrice(collateralToken.address, initialCollateralTokenPrice)).wait();
        await (await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice)).wait();

        depositAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(50);
        collateralAmount = ethers.BigNumber.from(10).pow(collateralApproved.decimals).mul(200);
        borrowedAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(20);

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();

        await (await pool.addLiquidity(borrowedToken.address, depositAmount)).wait();
        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();
        await (await marginLong.borrow(borrowedToken.address, borrowedAmount)).wait();
    });

    afterEach(async () => {
        const potentialCollateralTokens = [collateralToken, borrowedToken];
        for (const token of potentialCollateralTokens) {
            const amount = await marginLong.collateral(token.address, signerAddress);
            if (amount.gt(0)) await (await marginLong.removeCollateral(token.address, amount)).wait();
        }

        const LPTokenAmount = await lpToken.balanceOf(signerAddress);
        if (LPTokenAmount.gt(0)) await (await pool.removeLiquidity(lpToken.address, LPTokenAmount)).wait();
    });

    // it("should liquidate an account", async () => {
    //     expect(await marginLong.liquidatable(signerAddress)).to.equal(false);
    //     await shouldFail(async () => await marginLong.liquidateAccount(signerAddress));

    //     const [leverageNumerator, leverageDenominator] = await marginLong.currentLeverage(signerAddress);
    //     const [maxLeverageNumerator, maxLeverageDenominator] = await marginLong.maxLeverage();
    //     const [priceChangeNumerator, priceChangeDenominator] = [
    //         maxLeverageNumerator.mul(leverageDenominator).sub(leverageNumerator.mul(maxLeverageDenominator)).add(1),
    //         leverageNumerator.mul(maxLeverageNumerator),
    //     ];
    //     (await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice.mul(priceChangeDenominator.sub(priceChangeNumerator)).div(priceChangeDenominator))).wait();

    //     const timelockInitialBalance = await borrowedToken.balanceOf(timelock.address);

    //     expect(await marginLong.liquidatable(signerAddress)).to.equal(true);
    //     await (await marginLong.liquidateAccount(signerAddress)).wait();
    //     expect(await marginLong["isBorrowing(address)"](signerAddress)).to.equal(false);

    //     expect((await borrowedToken.balanceOf(timelock.address)).gt(timelockInitialBalance)).to.equal(true);

    //     expect((await pool.tvl(borrowedToken.address)).gt(depositAmount)).to.equal(true);
    // });

    // it("should reset an account", async () => {
    //     expect(await marginLong.resettable(signerAddress)).to.equal(false);
    //     await shouldFail(async () => await marginLong.resetAccount(signerAddress));

    //     await (await oracle.setPrice(collateralToken.address, 1)).wait();

    //     expect(await marginLong.resettable(signerAddress)).to.equal(true);
    //     await (await marginLong.resetAccount(signerAddress)).wait();
    //     expect(await marginLong["isBorrowing(address)"](signerAddress)).to.equal(false);

    //     expect((await marginLong.collateral(collateralToken.address, signerAddress)).lt(collateralAmount)).to.equal(true);
    //     expect((await pool.tvl(borrowedToken.address)).gt(depositAmount)).to.equal(true);
    // });

    it("should liquidate an account with the resolver", async () => {
        // **** Perhaps regarding the resolver, the amount that there is claimed to be sent to the contract is not actually in the contract ?

        expect((await resolver.checkLiquidate())[0]).to.equal(false);
        await shouldFail(async () => await resolver.executeLiquidate(signerAddress));

        const [leverageNumerator, leverageDenominator] = await marginLong.currentLeverage(signerAddress);
        const [maxLeverageNumerator, maxLeverageDenominator] = await marginLong.maxLeverage();
        const [priceChangeNumerator, priceChangeDenominator] = [
            maxLeverageNumerator.mul(leverageDenominator).sub(leverageNumerator.mul(maxLeverageDenominator)).add(1),
            leverageNumerator.mul(maxLeverageNumerator),
        ];
        (await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice.mul(priceChangeDenominator.sub(priceChangeNumerator)).div(priceChangeDenominator))).wait();

        expect((await resolver.checkLiquidate())[0]).to.equal(true);
        await (await resolver.executeLiquidate(signerAddress)).wait();

        // **** Also check if the deposited funds increased in value

        expect(await marginLong["isBorrowing(address)"](signerAddress)).to.equal(false);
    });

    // it("should reset an account with the resolver", async () => {});

    // it("should repay an account with profit", async () => {
    //     await (await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice.mul(110).div(100))).wait();

    //     const initialAccountPrice = await marginLong.collateralPrice(signerAddress);
    //     await (await marginLong["repayAccount()"]()).wait();
    //     expect((await marginLong.collateralPrice(signerAddress)).gt(initialAccountPrice)).to.equal(true);

    //     expect((await pool.tvl(borrowedToken.address)).lt(depositAmount)).to.equal(true);
    // });

    // it("should repay an account with a loss", async () => {
    //     const [leverageNumerator, leverageDenominator] = await marginLong.currentLeverage(signerAddress);
    //     const [maxLeverageNumerator, maxLeverageDenominator] = await marginLong.maxLeverage();
    //     const [priceChangeNumerator, priceChangeDenominator] = [
    //         maxLeverageNumerator.mul(leverageDenominator).sub(leverageNumerator.mul(maxLeverageDenominator)).sub(1),
    //         leverageNumerator.mul(maxLeverageNumerator),
    //     ];
    //     (await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice.mul(priceChangeDenominator.sub(priceChangeNumerator)).div(priceChangeDenominator))).wait();

    //     const initialAccountPrice = await marginLong.collateralPrice(signerAddress);
    //     await (await marginLong["repayAccount()"]()).wait();
    //     expect((await marginLong.collateralPrice(signerAddress)).lt(initialAccountPrice)).to.equal(true);

    //     expect((await pool.tvl(borrowedToken.address)).gt(depositAmount)).to.equal(true);
    // });

    // it("should liquidate an account that exceeds the leverage limit by its collateral falling in value whilst being above min collateral price", async () => {
    //     await marginLong["repayAccount()"]();
    //     await (await oracle.setPrice(borrowedToken.address, ethers.BigNumber.from(10).pow(priceDecimals).mul(300))).wait();

    //     await (await marginLong.borrow(borrowedToken.address, borrowedAmount)).wait();

    //     await (await oracle.setPrice(collateralToken.address, ethers.BigNumber.from(10).pow(priceDecimals).div(10))).wait();

    //     await (await marginLong.liquidateAccount(signerAddress)).wait();
    // });
});
