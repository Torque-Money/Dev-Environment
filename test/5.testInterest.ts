import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {approxEqual} from "../scripts/utils/utilsTest";
import {wait} from "../scripts/utils/utilsTest";
import {ERC20, LPool, MarginLong, OracleTest} from "../typechain-types";

describe("Interest", async function () {
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
    let borrowedAmount: BigNumber;

    beforeEach(async () => {
        collateralApproved = config.approved[0];
        collateralToken = await ethers.getContractAt("ERC20", collateralApproved.address);

        borrowedApproved = config.approved[1];
        borrowedToken = await ethers.getContractAt("ERC20", borrowedApproved.address);

        marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);
        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        oracle = await ethers.getContractAt("OracleTest", config.oracleAddress);

        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(borrowedToken.address));

        const priceDecimals = await oracle.priceDecimals();
        await (await oracle.setPrice(collateralToken.address, ethers.BigNumber.from(10).pow(priceDecimals))).wait();
        await (await oracle.setPrice(borrowedToken.address, ethers.BigNumber.from(10).pow(priceDecimals).mul(30))).wait();

        depositAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(50);
        const collateralAmount = ethers.BigNumber.from(10).pow(collateralApproved.decimals).mul(200);
        borrowedAmount = ethers.BigNumber.from(10).pow(borrowedApproved.decimals).mul(20);

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();

        await (await pool.addLiquidity(borrowedToken.address, depositAmount)).wait();
        await (await marginLong.addCollateral(collateralToken.address, collateralAmount)).wait();
    });

    afterEach(async () => {
        const potentialCollateralTokens = [collateralToken, borrowedToken];
        for (const token of potentialCollateralTokens) {
            const amount = await marginLong.collateral(token.address, signerAddress);
            if (amount.gt(0)) await (await marginLong.removeCollateral(token.address, amount)).wait();
        }

        const LPTokenAmount = await lpToken.balanceOf(signerAddress);
        if (LPTokenAmount.gt(0)) await (await pool.removeLiquidity(lpToken.address, LPTokenAmount)).wait();
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
