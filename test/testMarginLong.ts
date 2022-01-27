import {expect} from "chai";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/util/utilsTest";
import {ERC20, LPool, MarginLong} from "../typechain-types";

describe("MarginLong", async function () {
    let collateralApproved: any;
    let collateralToken: ERC20;

    let borrowedApproved: any;
    let borrowedToken: ERC20;

    let lpToken: ERC20;

    let marginLong: MarginLong;
    let pool: LPool;

    let signerAddress: string;

    beforeEach(async () => {
        collateralApproved = config.approved[0];
        collateralToken = await ethers.getContractAt("ERC20", collateralApproved.address);

        borrowedApproved = config.approved[1];
        borrowedToken = await ethers.getContractAt("ERC20", borrowedApproved.address);

        marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);

        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(borrowedToken.address));

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();
    });

    it("should prevent bad leverage positions and should open and repay a leveraged position", async () => {
        await shouldFail(async () => await marginLong.borrow(collateralToken.address, ethers.BigNumber.from(2).pow(255)));

        const tokenAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(50);

        const providedValue = await pool.addLiquidityOutLPTokens(borrowedToken.address, tokenAmount);
        await pool.addLiquidity(borrowedToken.address, tokenAmount);

        await shouldFail(async () => await marginLong.borrow(collateralToken.address, ethers.BigNumber.from(2).pow(255)));

        const collateralAmount = ethers.BigNumber.from(10).pow(collateralApproved.decimals).mul(200);
        await marginLong.addCollateral(collateralToken.address, collateralAmount);

        console.log("Signer address:", await marginLong.collateralPrice(signerAddress));

        await shouldFail(async () => await marginLong.borrow(collateralToken.address, ethers.BigNumber.from(2).pow(255)));

        const borrowedAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(1);
        await marginLong.borrow(borrowedToken.address, borrowedAmount);

        expect((await marginLong.getBorrowingAccounts()).length).to.not.equal(0);

        expect(await pool.liquidity(borrowedToken.address)).to.equal(tokenAmount.sub(borrowedAmount));
        expect(await marginLong.totalBorrowed(borrowedToken.address)).to.equal(borrowedAmount);
        expect(await marginLong.borrowed(borrowedToken.address, signerAddress)).to.equal(borrowedAmount);
        expect(await pool.claimed(borrowedToken.address, marginLong.address)).to.equal(borrowedAmount);

        await shouldFail(async () => await marginLong.removeCollateral(collateralToken.address, collateralValue));

        await marginLong.repayAccount(borrowedToken.address);

        expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

        const collateralValue = await marginLong.collateral(collateralToken.address, signerAddress);
        await marginLong.removeCollateral(collateralToken.address, collateralValue);

        expect(await pool.liquidity(borrowedToken.address)).to.equal(tokenAmount);
        expect(await pool.tvl(borrowedToken.address)).to.equal(tokenAmount);
        expect(await marginLong.totalBorrowed(borrowedToken.address)).to.equal(0);
        expect(await marginLong.borrowed(borrowedToken.address, signerAddress)).to.equal(0);
        expect(await pool.claimed(borrowedToken.address, marginLong.address)).to.equal(0);

        await pool.removeLiquidity(await pool.LPFromPT(borrowedToken.address), providedValue);
    });

    // it("deposit and undeposit collateral into the account", async () => {
    //     const initialBalance = await collateralToken.balanceOf(signerAddress);

    //     const tokenAmount = ethers.BigNumber.from(10).pow(collateralApproved.decimals).mul(1);
    //     await marginLong.addCollateral(collateralToken.address, tokenAmount);

    //     expect(await collateralToken.balanceOf(signerAddress)).to.equal(initialBalance.sub(tokenAmount));
    //     expect(await marginLong.collateral(collateralToken.address, signerAddress)).to.equal(tokenAmount);

    //     expect(await marginLong.totalCollateral(collateralToken.address)).to.equal(tokenAmount);
    //     expect(await collateralToken.balanceOf(marginLong.address)).to.equal(tokenAmount);

    //     await marginLong.removeCollateral(collateralToken.address, tokenAmount);

    //     expect(await collateralToken.balanceOf(signerAddress)).to.equal(initialBalance);
    //     expect(await marginLong.collateral(collateralToken.address, signerAddress)).to.equal(0);

    //     expect(await marginLong.totalCollateral(collateralToken.address)).to.equal(0);
    //     expect(await collateralToken.balanceOf(marginLong.address)).to.equal(0);
    // });

    // it("should not allow bad deposits", async () => {
    //     shouldFail(async () => await marginLong.addCollateral(lpToken.address, 0));
    //     shouldFail(async () => await marginLong.addCollateral(collateralToken.address, ethers.BigNumber.from(2).pow(255)));

    //     shouldFail(async () => await marginLong.removeCollateral(collateralToken.address, ethers.BigNumber.from(2).pow(255)));
    // });

    // it("should open and repay all leveraged positions", async () => {
    //     const tokenAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(50);

    //     const providedValue = await pool.addLiquidityOutLPTokens(borrowedToken.address, tokenAmount);
    //     await pool.addLiquidity(borrowedToken.address, tokenAmount);

    //     const collateralAmount = ethers.BigNumber.from(10).pow(collateralApproved.decimals).mul(200);
    //     await marginLong.addCollateral(collateralToken.address, collateralAmount);

    //     const borrowedAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(1);
    //     await marginLong.borrow(borrowedToken.address, borrowedAmount);

    //     expect((await marginLong.getBorrowingAccounts()).length).to.not.equal(0);

    //     await marginLong.repayAccountAll();

    //     expect((await marginLong.getBorrowingAccounts()).length).to.equal(0);

    //     const collateralValue = await marginLong.collateral(collateralToken.address, signerAddress);
    //     await marginLong.removeCollateral(collateralToken.address, collateralValue);

    //     expect(await pool.liquidity(borrowedToken.address)).to.equal(tokenAmount);
    //     expect(await pool.tvl(borrowedToken.address)).to.equal(tokenAmount);
    //     expect(await marginLong.totalBorrowed(borrowedToken.address)).to.equal(0);
    //     expect(await marginLong.borrowed(borrowedToken.address, signerAddress)).to.equal(0);
    //     expect(await pool.claimed(borrowedToken.address, marginLong.address)).to.equal(0);

    //     await pool.removeLiquidity(await pool.LPFromPT(borrowedToken.address), providedValue);
    // });
});
