import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {ERC20, FlashBorrower, FlashLender, LPool} from "../typechain-types";

describe("FlashLend", async function () {
    let tokenApproved: any;
    let token: ERC20;

    let lpToken: ERC20;

    let flashLender: FlashLender;
    let flashBorrower: FlashBorrower;
    let pool: LPool;

    let signerAddress: string;

    let depositAmount: BigNumber;

    beforeEach(async () => {
        tokenApproved = config.approved[1];
        token = await ethers.getContractAt("ERC20", tokenApproved.address);

        flashLender = await ethers.getContractAt("FlashLender", config.flashLender);
        flashBorrower = await ethers.getContractAt("FlashBorrower", config.flashBorrower);

        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);

        lpToken = await ethers.getContractAt("ERC20", await pool.PTFromLP(token.address));

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();

        depositAmount = ethers.BigNumber.from(10).pow(tokenApproved.decimals).mul(10);
        await (await pool.addLiquidity(token.address, depositAmount)).wait();
    });

    afterEach(async () => {
        const LPTokenAmount = await lpToken.balanceOf(signerAddress);
        if (LPTokenAmount.gt(0)) await (await pool.removeLiquidity(lpToken.address, LPTokenAmount)).wait();
    });

    it("should execute a flash loan successfully", async () => {
        const maxAmount = await flashLender.maxFlashLoan(token.address);
        expect(maxAmount).to.equal(depositAmount);

        const [feePercentNumerator, feePercentDenominator] = await flashLender.feePercent();
        const fee = await flashLender.flashFee(token.address, depositAmount);
        expect(fee).to.equal(depositAmount.mul(feePercentNumerator).div(feePercentDenominator));

        await (await token.transfer(flashBorrower.address, fee)).wait();

        await (await flashBorrower.callFlashLoan(token.address, depositAmount)).wait();

        expect((await pool.liquidity(token.address)).gt(depositAmount)).to.equal(true);
        expect((await pool.tvl(token.address)).gt(depositAmount)).to.equal(true);
        expect((await token.balanceOf(pool.address)).gt(depositAmount)).to.equal(true);
    });

    // It should attempt to borrow more than what is available

    // It should fail to repay what is required

    // It should attempt to repay more than what is available
});
