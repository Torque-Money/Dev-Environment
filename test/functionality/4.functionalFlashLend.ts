import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";

import {ERC20Upgradeable, FlashBorrowerTest, FlashLender, LPool} from "../../typechain-types";
import {shouldFail} from "../../scripts/utils/misc/utilTest";
import {getFlashLenderTokens, getTokenAmount} from "../../scripts/utils/misc/utilTokens";
import {chooseConfig} from "../../scripts/utils/config/utilConfig";
import {provideLiquidity, redeemLiquidity} from "../../scripts/utils/misc/utilPool";
import getConfigType from "../../scripts/utils/config/utilConfigTypeSelector";
import {BIG_NUM} from "../../scripts/utils/config/utilConstants";

describe("Interaction: FlashLend", () => {
    const configType = getConfigType(hre);
    const config = chooseConfig(configType);

    let flashLendToken: ERC20Upgradeable;

    let flashLendAmount: BigNumber;

    let flashLender: FlashLender;
    let flashBorrowerTest: FlashBorrowerTest;
    let pool: LPool;

    before(async () => {
        flashLendToken = (await getFlashLenderTokens(configType, hre))[0];

        flashLendAmount = (await getTokenAmount(hre, [flashLendToken]))[0];

        flashLender = await hre.ethers.getContractAt("FlashLender", config.contracts.flashLender);
        flashBorrowerTest = await hre.ethers.getContractAt("FlashBorrowerTest", config.contracts.flashBorrowerTest);
        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
    });

    beforeEach(async () => {
        await provideLiquidity(pool, [flashLendToken], [flashLendAmount]);
    });

    afterEach(async () => {
        await redeemLiquidity(configType, hre, pool);
    });

    it("should execute a flash loan successfully", async () => {
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

    it("should fail to borrow more than what is available", async () => {
        await shouldFail(async () => await flashBorrowerTest.callFlashLoan(flashLendToken.address, BIG_NUM, flashLender.address));
    });

    it("should fail to repay the loan", async () => {
        const maxAmount = await flashLender.maxFlashLoan(flashLendToken.address);

        await shouldFail(async () => await flashBorrowerTest.callFlashLoan(flashLendToken.address, maxAmount, flashLender.address));
    });

    it("should require a minimum of zero", async () => {
        await shouldFail(async () => await flashBorrowerTest.callFlashLoan(flashLendToken.address, 0, flashLender.address));
    });

    it("should fail to borrow an invalid token", async () => {
        await shouldFail(async () => await flashBorrowerTest.callFlashLoan(hre.ethers.constants.AddressZero, 0, flashLender.address));
    });
});
