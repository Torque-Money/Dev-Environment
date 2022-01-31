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

    let signerAddress: string;

    let depositAmount: BigNumber;
    let collateralAmount: BigNumber;
    let borrowedAmount: BigNumber;

    beforeEach(async () => {
        collateralApproved = config.approved[0];
        collateralToken = await ethers.getContractAt("ERC20", collateralApproved.address);

        borrowedApproved = config.approved[1];
        borrowedToken = await ethers.getContractAt("ERC20", borrowedApproved.address);

        depositAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(50);
        collateralAmount = ethers.BigNumber.from(10).pow(collateralApproved.decimals).mul(200);
        borrowedAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(10);

        marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);
        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        oracle = await ethers.getContractAt("OracleTest", config.oracleAddress);

        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(borrowedToken.address));

        const priceDecimals = await oracle.priceDecimals();
        await oracle.setPrice(collateralToken.address, ethers.BigNumber.from(10).pow(priceDecimals));
        await oracle.setPrice(borrowedToken.address, ethers.BigNumber.from(10).pow(priceDecimals).mul(20));

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

    it("should prevent bad leverage positions and should open and repay a leveraged position", async () => {
        await shouldFail(async () => await marginLong.borrow(collateralToken.address, ethers.BigNumber.from(2).pow(255)));

        await shouldFail(async () => await marginLong.borrow(collateralToken.address, ethers.BigNumber.from(2).pow(255)));

        await marginLong.addCollateral(collateralToken.address, collateralAmount);

        await shouldFail(async () => await marginLong.borrow(collateralToken.address, ethers.BigNumber.from(2).pow(255)));

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

        expect(await pool.liquidity(borrowedToken.address)).to.equal(depositAmount);
        expect(await pool.tvl(borrowedToken.address)).to.equal(depositAmount);
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

        expect(await pool.liquidity(borrowedToken.address)).to.equal(depositAmount);
        expect(await pool.tvl(borrowedToken.address)).to.equal(depositAmount);
        expect(await marginLong.totalBorrowed(borrowedToken.address)).to.equal(0);
        expect(await marginLong.borrowed(borrowedToken.address, signerAddress)).to.equal(0);
        expect(await pool.claimed(borrowedToken.address, marginLong.address)).to.equal(0);
    });
});