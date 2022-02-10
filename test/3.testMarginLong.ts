import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/util/utilsTest";
import {ERC20, LPool, MarginLong, OracleTest} from "../typechain-types";

describe("MarginLong", async function () {
    let collateralApproved: any;
    let collateralToken: ERC20;

    let borrowedApproved: any;
    let borrowedToken: ERC20;

    let lpToken: ERC20;

    let oracle: OracleTest;
    let marginLong: MarginLong;
    let pool: LPool;

    let priceDecimals: BigNumber;

    let signerAddress: string;

    let depositAmount: BigNumber;
    let collateralAmount: BigNumber;
    let borrowedAmount: BigNumber;

    beforeEach(async () => {
        collateralApproved = config.approved[0];
        collateralToken = await ethers.getContractAt("ERC20", collateralApproved.address);

        borrowedApproved = config.approved[1];
        borrowedToken = await ethers.getContractAt("ERC20", borrowedApproved.address);

        marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);
        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        oracle = await ethers.getContractAt("OracleTest", config.oracleAddress);

        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(borrowedToken.address));

        priceDecimals = await oracle.priceDecimals();
        await (await oracle.setPrice(collateralToken.address, ethers.BigNumber.from(10).pow(priceDecimals))).wait();
        await (await oracle.setPrice(borrowedToken.address, ethers.BigNumber.from(10).pow(priceDecimals).mul(30))).wait();

        depositAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(100);
        collateralAmount = ethers.BigNumber.from(10).pow(collateralApproved.decimals).mul(200);
        borrowedAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(20);

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();

        await (await pool.addLiquidity(borrowedToken.address, depositAmount)).wait();
    });

    afterEach(async () => {
        const LPTokenAmount = await lpToken.balanceOf(signerAddress);
        if (LPTokenAmount.gt(0)) await (await pool.removeLiquidity(lpToken.address, LPTokenAmount)).wait();
    });

    it("deposit and undeposit collateral into the account", async () => {
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
        shouldFail(async () => await marginLong.addCollateral(lpToken.address, 0));
        shouldFail(async () => await marginLong.addCollateral(collateralToken.address, ethers.BigNumber.from(2).pow(255)));

        shouldFail(async () => await marginLong.removeCollateral(collateralToken.address, ethers.BigNumber.from(2).pow(255)));
    });

    it("should prevent bad leverage positions", async () => {
        await shouldFail(async () => await marginLong.borrow(borrowedToken.address, ethers.BigNumber.from(2).pow(255)));

        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();

        await shouldFail(async () => await marginLong.borrow(borrowedToken.address, ethers.BigNumber.from(2).pow(255)));

        await (await oracle.setPrice(borrowedToken.address, ethers.BigNumber.from(10).pow(priceDecimals).mul(3000))).wait();
        await shouldFail(async () => await marginLong.borrow(borrowedToken.address, depositAmount));

        await (await marginLong.removeCollateral(collateralToken.address, collateralAmount)).wait();
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
