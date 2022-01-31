import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {ERC20, LPool, MarginLong, OracleTest} from "../typechain-types";

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

    let signerAddress: string;

    let depositAmount: BigNumber;
    let collateralAmount: BigNumber;
    let borrowedAmount: BigNumber;

    beforeEach(async () => {
        collateralApproved = config.approved[0];
        collateralToken = await ethers.getContractAt("ERC20", collateralApproved.address);

        borrowedApproved = config.approved[1];
        borrowedToken = await ethers.getContractAt("ERC20", borrowedApproved.address);

        depositAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(30);
        collateralAmount = ethers.BigNumber.from(10).pow(collateralApproved.decimals).mul(200);
        borrowedAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(10); // Test requires position to have a current leverage > 1 (just write this into the test ?)

        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        oracle = await ethers.getContractAt("OracleTest", config.oracleAddress);
        marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);

        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(borrowedToken.address));

        priceDecimals = await oracle.priceDecimals();
        initialCollateralTokenPrice = ethers.BigNumber.from(10).pow(priceDecimals);
        initialBorrowTokenPrice = ethers.BigNumber.from(10).pow(priceDecimals).mul(30);
        await oracle.setPrice(collateralToken.address, initialCollateralTokenPrice);
        await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice);

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();

        await pool.addLiquidity(borrowedToken.address, depositAmount);
        await marginLong.addCollateral(collateralToken.address, collateralAmount);
        await marginLong.borrow(borrowedToken.address, borrowedAmount);
    });

    afterEach(async () => {
        const potentialCollateralTokens = [collateralToken, borrowedToken];
        for (const token of potentialCollateralTokens) {
            const amount = await marginLong.collateral(token.address, signerAddress);
            if (amount.gt(0)) await marginLong.removeCollateral(token.address, amount);
        }

        const LPTokenAmount = await lpToken.balanceOf(signerAddress);
        if (LPTokenAmount.gt(0)) await pool.removeLiquidity(lpToken.address, LPTokenAmount);
    });

    it("should liquidate an account", async () => {
        const [leverageNumerator, leverageDenominator] = await marginLong.currentLeverage(signerAddress);
        const [maxLeverageNumerator, maxLeverageDenominator] = await marginLong.maxLeverage();
        const [priceChangeNumerator, priceChangeDenominator] = [
            maxLeverageNumerator.mul(leverageDenominator).sub(leverageNumerator.mul(maxLeverageDenominator)).add(1),
            leverageNumerator.mul(maxLeverageNumerator),
        ];
        await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice.mul(priceChangeDenominator.sub(priceChangeNumerator)).div(priceChangeDenominator));

        expect(await marginLong.liquidatable(signerAddress)).to.equal(true);
        await marginLong.liquidateAccount(signerAddress);
        expect(await marginLong["isBorrowing(address)"](signerAddress)).to.equal(false);

        expect((await pool.tvl(borrowedToken.address)).gt(depositAmount)).to.equal(true);
    });

    it("should reset an account", async () => {
        await oracle.setPrice(collateralToken.address, 1);

        expect(await marginLong.resettable(signerAddress)).to.equal(true);
        await marginLong.resetAccount(signerAddress);
        expect(await marginLong["isBorrowing(address)"](signerAddress)).to.equal(false);

        expect((await marginLong.collateral(collateralToken.address, signerAddress)).lt(collateralAmount)).to.equal(true);
        expect((await pool.tvl(borrowedToken.address)).gt(depositAmount)).to.equal(true);
    });

    it("should repay an account with profit", async () => {
        await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice.mul(110).div(100));

        const initialAccountPrice = await marginLong.collateralPrice(signerAddress);
        await marginLong["repayAccount()"]();
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
        await oracle.setPrice(borrowedToken.address, initialBorrowTokenPrice.mul(priceChangeDenominator.sub(priceChangeNumerator)).div(priceChangeDenominator));

        const initialAccountPrice = await marginLong.collateralPrice(signerAddress);
        await marginLong["repayAccount()"]();
        expect((await marginLong.collateralPrice(signerAddress)).lt(initialAccountPrice)).to.equal(true);

        expect((await pool.tvl(borrowedToken.address)).gt(depositAmount)).to.equal(true);
    });
});
