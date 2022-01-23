import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/util/utilsTest";
import {ERC20, LPool, MarginLong, OracleTest, Resolver} from "../typechain-types";

describe("Handle price movement", async function () {
    let pool: LPool;
    let oracle: OracleTest;
    let priceDecimals: BigNumber;
    let marginLong: MarginLong;
    let resolver: Resolver;
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
        resolver = await ethers.getContractAt("Resolver", config.resolverAddress);

        collateralToken = await ethers.getContractAt("ERC20", config.approved[0].address);
        borrowedToken = await ethers.getContractAt("ERC20", config.approved[1].address);
        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(borrowedToken.address));

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();

        priceDecimals = await oracle.priceDecimals();
        await oracle.setPrice(collateralToken.address, ethers.BigNumber.from(10).pow(priceDecimals));
        await oracle.setPrice(borrowedToken.address, ethers.BigNumber.from(10).pow(priceDecimals).mul(30));

        await pool.provideLiquidity(borrowedToken.address, addLiquidityAmount);
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
        await pool.redeemLiquidity(lpToken.address, LPTokenAmount);
    });

    it("should liquidate an account", async () => {
        const [initialMarginLevelNumerator, initialMarginLevelDenominator] = await marginLong.marginLevel(signerAddress);
        console.log("Liquidate: initial margin level", initialMarginLevelNumerator, initialMarginLevelDenominator);

        const newPrice = ethers.BigNumber.from(10).pow(priceDecimals).mul(10);
        await oracle.setPrice(borrowedToken.address, newPrice);

        const [newMarginLevelNumerator, newMarginLevelDenominator] = await marginLong.marginLevel(signerAddress);
        console.log("Liquidate: new margin level", newMarginLevelNumerator, newMarginLevelDenominator);

        const [minMarginLevelNumerator, minMarginLevelDenominator] = await marginLong.minMarginLevel();
        console.log("Liquidate: min margin level", minMarginLevelNumerator, minMarginLevelDenominator);

        expect(await marginLong.liquidatable(signerAddress)).to.equal(true);
        await marginLong.liquidateAccount(signerAddress);
    });

    it("should reset an account", async () => {});

    it("should repay an account with profit", async () => {});

    it("should repay an account with a loss", async () => {});
});
