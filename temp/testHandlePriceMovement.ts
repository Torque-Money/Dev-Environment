import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {ERC20, LPool, MarginLong, OracleTest} from "../typechain-types";

describe("Handle price movement", async function () {
    let pool: LPool;
    let oracle: OracleTest;
    let priceDecimals: BigNumber;
    let marginLong: MarginLong;
    let collateralToken: ERC20;
    let borrowedToken: ERC20;
    let lpToken: ERC20;
    let signerAddress: string;

    const addLiquidityAmount = ethers.BigNumber.from(10).pow(config.approved[1].decimals).mul(30);
    const addCollateralAmount = ethers.BigNumber.from(10).pow(config.approved[0].decimals).mul(200);
    const borrowAmount = ethers.BigNumber.from(10).pow(config.approved[1].decimals).mul(30);

    beforeEach(async () => {
        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        oracle = await ethers.getContractAt("OracleTest", config.oracleAddress);
        marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);

        collateralToken = await ethers.getContractAt("ERC20", config.approved[0].address);
        borrowedToken = await ethers.getContractAt("ERC20", config.approved[1].address);
        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(borrowedToken.address));

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();

        priceDecimals = await oracle.priceDecimals();
        await oracle.setPrice(collateralToken.address, ethers.BigNumber.from(10).pow(priceDecimals));
        await oracle.setPrice(borrowedToken.address, ethers.BigNumber.from(10).pow(priceDecimals).mul(30));

        await pool.addLiquidity(borrowedToken.address, addLiquidityAmount);
        await marginLong.addCollateral(collateralToken.address, addCollateralAmount);
        await marginLong.borrow(borrowedToken.address, borrowAmount);
    });

    afterEach(async () => {
        const potentialCollateralTokens = [collateralToken, borrowedToken];
        for (const token of potentialCollateralTokens) {
            const amount = await marginLong.collateral(token.address, signerAddress);
            if (amount.gt(0)) await marginLong.removeCollateral(token.address, amount);
        }

        const LPTokenAmount = await lpToken.balanceOf(signerAddress);
        await pool.removeLiquidity(lpToken.address, LPTokenAmount);
    });

    it("should liquidate an account", async () => {
        const newPrice = ethers.BigNumber.from(10).pow(priceDecimals).mul(10);
        await oracle.setPrice(borrowedToken.address, newPrice);

        expect(await marginLong.liquidatable(signerAddress)).to.equal(true);
        await marginLong.liquidateAccount(signerAddress);
        expect(await marginLong["isBorrowing(address)"](signerAddress)).to.equal(false);

        expect((await pool.tvl(borrowedToken.address)).gt(addLiquidityAmount)).to.equal(true);
    });

    it("should reset an account", async () => {
        const newPrice = ethers.BigNumber.from(10).pow(priceDecimals).div(3);
        await oracle.setPrice(collateralToken.address, newPrice);

        expect(await marginLong.resettable(signerAddress)).to.equal(true);
        await marginLong.resetAccount(signerAddress);
        expect(await marginLong["isBorrowing(address)"](signerAddress)).to.equal(false);

        expect((await marginLong.collateral(collateralToken.address, signerAddress)).lt(addCollateralAmount)).to.equal(true);
        expect((await pool.tvl(borrowedToken.address)).gt(addLiquidityAmount)).to.equal(true);
    });

    it("should repay an account with profit", async () => {
        const newPrice = ethers.BigNumber.from(10).pow(priceDecimals).mul(40);
        await oracle.setPrice(borrowedToken.address, newPrice);

        const initialAccountPrice = await marginLong.collateralPrice(signerAddress);
        await marginLong.repayAccountAll();
        expect((await marginLong.collateralPrice(signerAddress)).gt(initialAccountPrice)).to.equal(true);

        expect((await pool.tvl(borrowedToken.address)).lt(addLiquidityAmount)).to.equal(true);
    });

    it("should repay an account with a loss", async () => {
        const newPrice = ethers.BigNumber.from(10).pow(priceDecimals).mul(20);
        await oracle.setPrice(borrowedToken.address, newPrice);

        const initialAccountPrice = await marginLong.collateralPrice(signerAddress);
        await marginLong.repayAccountAll();
        expect((await marginLong.collateralPrice(signerAddress)).lt(initialAccountPrice)).to.equal(true);

        expect((await pool.tvl(borrowedToken.address)).gt(addLiquidityAmount)).to.equal(true);
    });
});