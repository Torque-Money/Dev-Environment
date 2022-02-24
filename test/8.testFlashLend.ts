import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";

import {FlashBorrowerTest, FlashLender, LPool} from "../typechain-types";
import {shouldFail} from "../scripts/utils/helpers/utilTest";
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

    let signerAddress: string;

    this.beforeAll(async () => {
        flashLendTokens = await getFlashLenderTokens(configType, hre);

        flashLendAmounts = await getTokenAmount(
            hre,
            flashLendTokens.map((token) => token.token)
        );

        flashLender = await hre.ethers.getContractAt("FlashLender", config.contracts.flashLender);
        flashBorrowerTest = await hre.ethers.getContractAt("FlashBorrowerTest", config.contracts.flashBorrowerTest);
        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);

        signerAddress = await hre.ethers.provider.getSigner().getAddress();
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
        const maxAmount = await flashLender.maxFlashLoan(token.address);
        expect(maxAmount).to.equal(depositAmount);

        const [feePercentNumerator, feePercentDenominator] = await flashLender.feePercent();
        const fee = await flashLender.flashFee(token.address, maxAmount);
        expect(fee).to.equal(maxAmount.mul(feePercentNumerator).div(feePercentDenominator));

        await (await token.transfer(flashBorrower.address, fee)).wait();

        await (await flashBorrower.callFlashLoan(token.address, maxAmount)).wait();

        expect((await pool.liquidity(token.address)).gt(depositAmount)).to.equal(true);
        expect((await pool.tvl(token.address)).gt(depositAmount)).to.equal(true);
        expect((await token.balanceOf(pool.address)).gt(depositAmount)).to.equal(true);
    });

    it("should fail to borrow more than what is available", async () => {
        const maxAmount = await flashLender.maxFlashLoan(token.address);

        await shouldFail(async () => await flashBorrower.callFlashLoan(token.address, maxAmount.add(1)));
    });

    it("should fail to repay the loan", async () => {
        const maxAmount = await flashLender.maxFlashLoan(token.address);

        await shouldFail(async () => await flashBorrower.callFlashLoan(token.address, maxAmount));
    });

    it("should require a minimum of zero", async () => {
        await shouldFail(async () => await flashBorrower.callFlashLoan(token.address, 0));
    });

    // **** Test the flashlend of an invalid token
});
