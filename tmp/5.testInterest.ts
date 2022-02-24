import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";

import {IOracle, LPool, MarginLong, OracleTest} from "../typechain-types";
import {approxEqual} from "../scripts/utils/helpers/utilTest";
import {wait} from "../scripts/utils/helpers/utilTest";
import {getPoolTokens, getTokenAmount, Token} from "../scripts/utils/helpers/utilTokens";
import {chooseConfig, ConfigType} from "../scripts/utils/utilConfig";
import {setPrice} from "../scripts/utils/helpers/utilOracle";
import {provideLiquidity, redeemLiquidity} from "../scripts/utils/helpers/utilPool";
import {addCollateral, removeCollateral} from "../scripts/utils/helpers/utilMarginLong";

describe("Interest", async function () {
    const configType: ConfigType = "fork";
    const config = chooseConfig(configType);

    let poolTokens: Token[];
    let collateralTokens: Token[];
    let borrowTokens: Token[];

    let provideAmounts: BigNumber[];
    let collateralAmounts: BigNumber[];
    let borrowAmounts: BigNumber[];

    let oracle: IOracle;
    let marginLong: MarginLong;
    let pool: LPool;

    let signerAddress: string;

    this.beforeAll(async () => {
        poolTokens = await getPoolTokens(configType, hre);
        collateralTokens = await getMarginLongCollateralTokens(configType, hre);
        borrowTokens = await getMarginLongBorrowTokens(configType, hre);

        provideAmounts = await getTokenAmount(
            hre,
            poolTokens.map((token) => token.token)
        );
        collateralAmounts = await getTokenAmount(
            hre,
            collateralTokens.map((token) => token.token)
        );
        borrowAmounts = await getTokenAmount(
            hre,
            borrowTokens.map((token) => token.token)
        );

        marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress);
        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
        oracle = await hre.ethers.getContractAt("IOracle", config.contracts.oracleAddress);

        signerAddress = await hre.ethers.provider.getSigner().getAddress();

        for (const token of poolTokens.map((token) => token.token)) await setPrice(oracle, token, initialPoolTokenPrice);
        for (const token of collateralTokens.map((token) => token.token)) await setPrice(oracle, token, initialCollateralTokenPrice);
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
        const maxUtilization = await pool.maxUtilization(borrowedToken.address);
        const tempBorrowAmount = depositAmount.mul(maxUtilization[0]).div(maxUtilization[1]).div(2);
        await (await marginLong.borrow(borrowedToken.address, tempBorrowAmount)).wait();

        const [maxInterestMinNumerator, maxInterestMinDenominator] = await pool.maxInterestMin(borrowedToken.address);
        const [interestNumerator, interestDenominator] = await pool.interestRate(borrowedToken.address);
        expect(interestNumerator.mul(maxInterestMinDenominator).mul(2)).to.equal(maxInterestMinNumerator.mul(interestDenominator));

        await (await marginLong["repayAccount(address)"](borrowedToken.address)).wait();
    });

    it("should borrow at the max utilization", async () => {
        const maxUtilization = await pool.maxUtilization(borrowedToken.address);
        const tempBorrowAmount = depositAmount.mul(maxUtilization[0]).div(maxUtilization[1]);
        await (await marginLong.borrow(borrowedToken.address, tempBorrowAmount)).wait();

        const [maxInterestMinNumerator, maxInterestMinDenominator] = await pool.maxInterestMin(borrowedToken.address);
        const [interestNumerator, interestDenominator] = await pool.interestRate(borrowedToken.address);
        expect(interestNumerator.mul(maxInterestMinDenominator)).to.equal(maxInterestMinNumerator.mul(interestDenominator));

        await (await marginLong["repayAccount(address)"](borrowedToken.address)).wait();
    });

    it("should borrow below 100% utilization", async () => {
        const maxUtilization = await pool.maxUtilization(borrowedToken.address);

        const tempBorrowAmount = depositAmount.mul(maxUtilization[0].add(maxUtilization[1])).div(maxUtilization[1]).div(2);
        await (await marginLong.borrow(borrowedToken.address, tempBorrowAmount)).wait();

        const [maxInterestMinNumerator, maxInterestMinDenominator] = await pool.maxInterestMin(borrowedToken.address);
        const [maxInterestMaxNumerator, maxInterestMaxDenominator] = await pool.maxInterestMax(borrowedToken.address);
        const [interestNumerator, interestDenominator] = await pool.interestRate(borrowedToken.address);
        expect(interestNumerator.mul(maxInterestMinDenominator).mul(maxInterestMaxDenominator).mul(2)).to.equal(
            interestDenominator.mul(maxInterestMaxNumerator.mul(maxInterestMinDenominator).add(maxInterestMinNumerator.mul(maxInterestMaxDenominator)))
        );

        await (await marginLong["repayAccount(address)"](borrowedToken.address)).wait();
    });

    it("should borrow at 100% utilization", async () => {
        await (await marginLong.borrow(borrowedToken.address, depositAmount)).wait();

        const [maxInterestMaxNumerator, maxInterestMaxDenominator] = await pool.maxInterestMax(borrowedToken.address);
        const [interestNumerator, interestDenominator] = await pool.interestRate(borrowedToken.address);
        expect(interestNumerator.mul(maxInterestMaxDenominator)).to.equal(maxInterestMaxNumerator.mul(interestDenominator));

        await (await marginLong["repayAccount(address)"](borrowedToken.address)).wait();
    });

    it("should accumulate interest over the given year as according to the rate", async () => {
        await (await marginLong.borrow(borrowedToken.address, borrowedAmount)).wait();

        const [interestNumerator, interestDenominator] = await pool.interestRate(borrowedToken.address);
        const timePerInterestApplication = await pool.timePerInterestApplication();
        await wait(timePerInterestApplication);

        const interest = await marginLong["interest(address,address)"](borrowedToken.address, signerAddress);
        const initialBorrowPrice = await marginLong["initialBorrowPrice(address,address)"](borrowedToken.address, signerAddress);
        const expectedInterest = initialBorrowPrice.mul(interestNumerator).div(interestDenominator);
        await approxEqual(interest, expectedInterest, 3);
        expect(await marginLong.accountPrice(signerAddress)).to.equal((await marginLong.collateralPrice(signerAddress)).sub(interest));

        await (await marginLong["repayAccount(address)"](borrowedToken.address)).wait();
    });

    it("should accumulate the given interest first before borrowing more", async () => {
        await (await marginLong.borrow(borrowedToken.address, borrowedAmount.div(2))).wait();

        const timePerInterestApplication = await pool.timePerInterestApplication();

        const [initialInterestRateNumerator, initialInterestRateDenominator] = await pool.interestRate(borrowedToken.address);
        await wait(timePerInterestApplication);
        const initialInterest = await marginLong["interest(address,address)"](borrowedToken.address, signerAddress);

        await (await marginLong.borrow(borrowedToken.address, borrowedAmount.div(2))).wait();

        const [currentInterestRateNumerator, currentInterestRateDenominator] = await pool.interestRate(borrowedToken.address);
        await wait(timePerInterestApplication);

        const currentInterest = await marginLong["interest(address,address)"](borrowedToken.address, signerAddress);

        expect(currentInterestRateNumerator.mul(initialInterestRateDenominator)).to.not.equal(initialInterestRateNumerator.mul(currentInterestRateDenominator));

        const initialBorrowPrice = await marginLong["initialBorrowPrice(address,address)"](borrowedToken.address, signerAddress);
        const expectedCurrentInterest = initialInterest.add(initialBorrowPrice.mul(currentInterestRateNumerator).div(currentInterestRateDenominator));
        await approxEqual(currentInterest, expectedCurrentInterest, 3);

        await (await marginLong["repayAccount(address)"](borrowedToken.address)).wait();
    });
});
