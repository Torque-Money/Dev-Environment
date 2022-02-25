import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";

import {LPool, MarginLong, OracleTest} from "../typechain-types";
import {approxEqual, BORROW_PRICE, COLLATERAL_PRICE} from "../scripts/utils/helpers/utilTest";
import {wait} from "../scripts/utils/helpers/utilTest";
import {getCollateralTokens, getPoolTokens, getTokenAmount, Token} from "../scripts/utils/helpers/utilTokens";
import {chooseConfig, ConfigType} from "../scripts/utils/utilConfig";
import {setPrice} from "../scripts/utils/helpers/utilOracle";
import {provideLiquidity, redeemLiquidity} from "../scripts/utils/helpers/utilPool";
import {addCollateral, minCollateralAmount, removeCollateral} from "../scripts/utils/helpers/utilMarginLong";

describe("Interest", async function () {
    const configType: ConfigType = "fork";
    const config = chooseConfig(configType);

    let poolTokens: Token[];
    let collateralTokens: Token[];

    let provideAmounts: BigNumber[];
    let collateralAmounts: BigNumber[];

    let oracle: OracleTest;
    let marginLong: MarginLong;
    let pool: LPool;

    let signerAddress: string;

    this.beforeAll(async () => {
        poolTokens = await getPoolTokens(configType, hre);
        collateralTokens = await getCollateralTokens(configType, hre);

        marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress);
        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
        oracle = await hre.ethers.getContractAt("OracleTest", config.contracts.oracleAddress);

        // **** In here this should really just be the given collateral amounts that have already been deposited (thus we will have to do this after the calculation has been made)
        provideAmounts = await getTokenAmount(
            hre,
            poolTokens.map((token) => token.token)
        );

        collateralAmounts = [];
        for (const {token} of collateralTokens) collateralAmounts.push(await minCollateralAmount(marginLong, oracle, token));

        signerAddress = await hre.ethers.provider.getSigner().getAddress();

        for (const token of poolTokens.map((token) => token.token)) await setPrice(oracle, token, BORROW_PRICE);
        for (const token of collateralTokens.map((token) => token.token)) await setPrice(oracle, token, COLLATERAL_PRICE);
    });

    this.beforeEach(async () => {
        await provideLiquidity(
            pool,
            poolTokens.map((token) => token.token),
            provideAmounts
        );

        await addCollateral(
            marginLong,
            collateralTokens.map((token) => token.token),
            collateralAmounts
        );
    });

    this.afterEach(async () => {
        await removeCollateral(configType, hre, marginLong);
        await redeemLiquidity(configType, hre, pool);
    });

    it("should borrow below the max utilization", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;
        const provideAmount = provideAmounts[index];

        const maxUtilization = await pool.maxUtilization(poolToken.address);
        const tempBorrowAmount = provideAmount.mul(maxUtilization[0]).div(maxUtilization[1]).div(2);
        await (await marginLong.borrow(poolToken.address, tempBorrowAmount)).wait();

        const [maxInterestMinNumerator, maxInterestMinDenominator] = await pool.maxInterestMin(poolToken.address);
        const [interestNumerator, interestDenominator] = await pool.interestRate(poolToken.address);
        expect(interestNumerator.mul(maxInterestMinDenominator).mul(2)).to.equal(maxInterestMinNumerator.mul(interestDenominator));

        await (await marginLong["repayAccount(address)"](poolToken.address)).wait();
    });

    it("should borrow at the max utilization", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;
        const provideAmount = provideAmounts[index];

        const maxUtilization = await pool.maxUtilization(poolToken.address);
        const tempBorrowAmount = provideAmount.mul(maxUtilization[0]).div(maxUtilization[1]);
        await (await marginLong.borrow(poolToken.address, tempBorrowAmount)).wait();

        const [maxInterestMinNumerator, maxInterestMinDenominator] = await pool.maxInterestMin(poolToken.address);
        const [interestNumerator, interestDenominator] = await pool.interestRate(poolToken.address);
        expect(interestNumerator.mul(maxInterestMinDenominator)).to.equal(maxInterestMinNumerator.mul(interestDenominator));

        await (await marginLong["repayAccount(address)"](poolToken.address)).wait();
    });

    it("should borrow below 100% utilization", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;
        const provideAmount = provideAmounts[index];

        const maxUtilization = await pool.maxUtilization(poolToken.address);

        const tempBorrowAmount = provideAmount.mul(maxUtilization[0].add(maxUtilization[1])).div(maxUtilization[1]).div(2);
        await (await marginLong.borrow(poolToken.address, tempBorrowAmount)).wait();

        const [maxInterestMinNumerator, maxInterestMinDenominator] = await pool.maxInterestMin(poolToken.address);
        const [maxInterestMaxNumerator, maxInterestMaxDenominator] = await pool.maxInterestMax(poolToken.address);
        const [interestNumerator, interestDenominator] = await pool.interestRate(poolToken.address);
        expect(interestNumerator.mul(maxInterestMinDenominator).mul(maxInterestMaxDenominator).mul(2)).to.equal(
            interestDenominator.mul(maxInterestMaxNumerator.mul(maxInterestMinDenominator).add(maxInterestMinNumerator.mul(maxInterestMaxDenominator)))
        );

        await (await marginLong["repayAccount(address)"](poolToken.address)).wait();
    });

    it("should borrow at 100% utilization", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;
        const provideAmount = provideAmounts[index];

        await (await marginLong.borrow(poolToken.address, provideAmount)).wait();

        const [maxInterestMaxNumerator, maxInterestMaxDenominator] = await pool.maxInterestMax(poolToken.address);
        const [interestNumerator, interestDenominator] = await pool.interestRate(poolToken.address);
        expect(interestNumerator.mul(maxInterestMaxDenominator)).to.equal(maxInterestMaxNumerator.mul(interestDenominator));

        await (await marginLong["repayAccount(address)"](poolToken.address)).wait();
    });

    it("should accumulate interest over the given year as according to the rate", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;
        const provideAmount = provideAmounts[index];

        await (await marginLong.borrow(poolToken.address, provideAmount)).wait();

        const [interestNumerator, interestDenominator] = await pool.interestRate(poolToken.address);
        const timePerInterestApplication = await pool.timePerInterestApplication();
        await wait(timePerInterestApplication);

        const interest = await marginLong["interest(address,address)"](poolToken.address, signerAddress);
        const initialBorrowPrice = await marginLong["initialBorrowPrice(address,address)"](poolToken.address, signerAddress);
        const expectedInterest = initialBorrowPrice.mul(interestNumerator).div(interestDenominator);
        await approxEqual(interest, expectedInterest, 3);
        expect(await marginLong.accountPrice(signerAddress)).to.equal((await marginLong.collateralPrice(signerAddress)).sub(interest));

        await (await marginLong["repayAccount(address)"](poolToken.address)).wait();
    });

    it("should accumulate the given interest first before borrowing more", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;
        const provideAmount = provideAmounts[index];

        await (await marginLong.borrow(poolToken.address, provideAmount.div(2))).wait();

        const timePerInterestApplication = await pool.timePerInterestApplication();

        const [initialInterestRateNumerator, initialInterestRateDenominator] = await pool.interestRate(poolToken.address);
        await wait(timePerInterestApplication);
        const initialInterest = await marginLong["interest(address,address)"](poolToken.address, signerAddress);

        await (await marginLong.borrow(poolToken.address, provideAmount.div(2))).wait();

        const [currentInterestRateNumerator, currentInterestRateDenominator] = await pool.interestRate(poolToken.address);
        await wait(timePerInterestApplication);

        const currentInterest = await marginLong["interest(address,address)"](poolToken.address, signerAddress);

        expect(currentInterestRateNumerator.mul(initialInterestRateDenominator)).to.not.equal(initialInterestRateNumerator.mul(currentInterestRateDenominator));

        const initialBorrowPrice = await marginLong["initialBorrowPrice(address,address)"](poolToken.address, signerAddress);
        const expectedCurrentInterest = initialInterest.add(initialBorrowPrice.mul(currentInterestRateNumerator).div(currentInterestRateDenominator));
        await approxEqual(currentInterest, expectedCurrentInterest, 3);

        await (await marginLong["repayAccount(address)"](poolToken.address)).wait();
    });
});
