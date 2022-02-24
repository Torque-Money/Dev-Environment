import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";

import {FlashBorrowerTest, FlashLender, LPool} from "../typechain-types";
import {BIG_NUM, shouldFail} from "../scripts/utils/helpers/utilTest";
import {getFlashLenderTokens, getTokenAmount, Token} from "../scripts/utils/helpers/utilTokens";
import {chooseConfig, ConfigType} from "../scripts/utils/utilConfig";
import {provideLiquidity, redeemLiquidity} from "../scripts/utils/helpers/utilPool";

describe("FlashLend", async function () {
    const configType: ConfigType = "fork";
    const config = chooseConfig(configType);

    let flashLendTokens: Token[];

    let flashLendAmounts: BigNumber[];

    let flashLender: FlashLender;
    let flashBorrowerTest: FlashBorrowerTest;
    let pool: LPool;

    this.beforeAll(async () => {
        flashLendTokens = await getFlashLenderTokens(configType, hre);

        flashLendAmounts = await getTokenAmount(
            hre,
            flashLendTokens.map((token) => token.token)
        );

        flashLender = await hre.ethers.getContractAt("FlashLender", config.contracts.flashLender);
        flashBorrowerTest = await hre.ethers.getContractAt("FlashBorrowerTest", config.contracts.flashBorrowerTest);
        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
    });

    this.beforeEach(async () => {
        await provideLiquidity(
            pool,
            flashLendTokens.map((token) => token.token),
            flashLendAmounts
        );
    });

    this.afterEach(async () => {
        await redeemLiquidity(configType, hre, pool);
    });

    it("should execute a flash loan successfully", async () => {
        const index = 0;
        const flashLendToken = flashLendTokens[index].token;
        const flashLendAmount = flashLendAmounts[index];

        const maxAmount = await flashLender.maxFlashLoan(flashLendToken.address);
        expect(maxAmount).to.equal(flashLendAmount);

        const [feePercentNumerator, feePercentDenominator] = await flashLender.feePercent();
        const fee = await flashLender.flashFee(flashLendToken.address, maxAmount);
        expect(fee).to.equal(maxAmount.mul(feePercentNumerator).div(feePercentDenominator));

        await (await flashLendToken.transfer(flashBorrowerTest.address, fee)).wait();

        await (await flashBorrowerTest.callFlashLoan(flashLendToken.address, maxAmount, flashLender.address)).wait();

        expect((await pool.liquidity(flashLendToken.address)).gt(flashLendAmount)).to.equal(true);
        expect((await pool.totalAmountLocked(flashLendToken.address)).gt(flashLendAmount)).to.equal(true);
        expect((await flashLendToken.balanceOf(pool.address)).gt(flashLendAmount)).to.equal(true);
    });

    // it("should fail to borrow more than what is available", async () => {
    //     const index = 0;
    //     const flashLendToken = flashLendTokens[index].token;

    //     const maxAmount = await flashLender.maxFlashLoan(flashLendToken.address);

    //     await shouldFail(async () => await flashBorrowerTest.callFlashLoan(flashLendToken.address, BIG_NUM, flashLender.address));
    // });

    // it("should fail to repay the loan", async () => {
    //     const index = 0;
    //     const flashLendToken = flashLendTokens[index].token;

    //     const maxAmount = await flashLender.maxFlashLoan(flashLendToken.address);

    //     await shouldFail(async () => await flashBorrowerTest.callFlashLoan(flashLendToken.address, maxAmount, flashLender.address));
    // });

    // it("should require a minimum of zero", async () => {
    //     const index = 0;
    //     const flashLendToken = flashLendTokens[index].token;

    //     await shouldFail(async () => await flashBorrowerTest.callFlashLoan(flashLendToken.address, 0, flashLender.address));
    // });

    // it("should fail to borrow an invalid token", async () => {
    //     await shouldFail(async () => await flashBorrowerTest.callFlashLoan(hre.ethers.constants.AddressZero, 0, flashLender.address));
    // });
});
