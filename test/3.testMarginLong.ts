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
        await oracle.setPrice(collateralToken.address, ethers.BigNumber.from(10).pow(priceDecimals));
        await oracle.setPrice(borrowedToken.address, ethers.BigNumber.from(10).pow(priceDecimals).mul(30));

        depositAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(100);
        collateralAmount = ethers.BigNumber.from(10).pow(collateralApproved.decimals).mul(200);
        borrowedAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(20);

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();

        await pool.addLiquidity(borrowedToken.address, depositAmount);
    });

    afterEach(async () => {
        const LPTokenAmount = await lpToken.balanceOf(signerAddress);
        if (LPTokenAmount.gt(0)) await pool.removeLiquidity(await pool.LPFromPT(borrowedToken.address), LPTokenAmount);
    });

    it("deposit and undeposit collateral into the account", async () => {
        const initialBalance = await collateralToken.balanceOf(signerAddress);
        await marginLong.addCollateral(collateralToken.address, collateralAmount);

        expect(await collateralToken.balanceOf(signerAddress)).to.equal(initialBalance.sub(collateralAmount));
        expect(await marginLong.collateral(collateralToken.address, signerAddress)).to.equal(collateralAmount);

        expect(await marginLong.totalCollateral(collateralToken.address)).to.equal(collateralAmount);
        expect(await collateralToken.balanceOf(marginLong.address)).to.equal(collateralAmount);

        await marginLong.removeCollateral(collateralToken.address, collateralAmount);

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

        await marginLong.addCollateral(collateralToken.address, collateralAmount);

        await shouldFail(async () => await marginLong.borrow(borrowedToken.address, ethers.BigNumber.from(2).pow(255)));

        await oracle.setPrice(borrowedToken.address, ethers.BigNumber.from(10).pow(priceDecimals).mul(3000));
        await shouldFail(async () => await marginLong.borrow(borrowedToken.address, depositAmount));

        await marginLong.removeCollateral(collateralToken.address, collateralAmount);
    });

    it("should open and repay a leveraged position", async () => {
        await marginLong.borrow(borrowedToken.address, borrowedAmount);

        expect((await marginLong.getBorrowingAccounts()).length).to.not.equal(0);

        expect(await pool.liquidity(borrowedToken.address)).to.equal(depositAmount.sub(borrowedAmount));
        expect(await marginLong.totalBorrowed(borrowedToken.address)).to.equal(borrowedAmount);
        expect(await marginLong.borrowed(borrowedToken.address, signerAddress)).to.equal(borrowedAmount);
        expect(await pool.claimed(borrowedToken.address, marginLong.address)).to.equal(borrowedAmount);

        await shouldFail(async () => await marginLong.removeCollateral(collateralToken.address, collateralValue));

        await marginLong["repayAccount(address)"](borrowedToken.address);

        expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

        const collateralValue = await marginLong.collateral(collateralToken.address, signerAddress);
        await marginLong.removeCollateral(collateralToken.address, collateralValue);

        expect((await pool.liquidity(borrowedToken.address)).gte(depositAmount)).to.equal(true);
        expect((await pool.tvl(borrowedToken.address)).gte(depositAmount)).to.equal(true);
        expect(await marginLong.totalBorrowed(borrowedToken.address)).to.equal(0);
        expect(await marginLong.borrowed(borrowedToken.address, signerAddress)).to.equal(0);
        expect(await pool.claimed(borrowedToken.address, marginLong.address)).to.equal(0);
    });

    it("should open and repay all leveraged positions", async () => {
        await marginLong.addCollateral(collateralToken.address, collateralAmount);

        await marginLong.borrow(borrowedToken.address, borrowedAmount);

        expect((await marginLong.getBorrowingAccounts()).length).to.not.equal(0);

        await marginLong["repayAccount()"]();

        expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

        const collateralValue = await marginLong.collateral(collateralToken.address, signerAddress);
        await marginLong.removeCollateral(collateralToken.address, collateralValue);

        expect((await pool.liquidity(borrowedToken.address)).gte(depositAmount)).to.equal(true);
        expect((await pool.tvl(borrowedToken.address)).gte(depositAmount)).to.equal(true);
        expect(await marginLong.totalBorrowed(borrowedToken.address)).to.equal(0);
        expect(await marginLong.borrowed(borrowedToken.address, signerAddress)).to.equal(0);
        expect(await pool.claimed(borrowedToken.address, marginLong.address)).to.equal(0);
    });

    it("should borrow against equity", async () => {
        await marginLong.addCollateral(collateralToken.address, collateralAmount);

        await marginLong.borrow(borrowedToken.address, borrowedAmount);

        const [initialMarginLevelNumerator, initialMarginLevelDenominator] = await marginLong.marginLevel(signerAddress);

        await oracle.setPrice(borrowedToken.address, ethers.BigNumber.from(10).pow(priceDecimals).mul(3000));

        const [currentMarginLevelNumerator, currentMarginLevelDenominator] = await marginLong.marginLevel(signerAddress);

        expect(currentMarginLevelNumerator.mul(initialMarginLevelDenominator).gt(initialMarginLevelNumerator.mul(currentMarginLevelDenominator))).to.equal(true);

        await marginLong["repayAccount()"]();
        await marginLong.removeCollateral(collateralToken.address, collateralAmount);
    });
});
