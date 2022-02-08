import {ethers} from "hardhat";
import config from "../config.fork.json";
import {ERC20, FlashBorrower, FlashLender, LPool} from "../typechain-types";

describe("FlashLend", async function () {
    let borrowApproved: any;
    let borrowToken: ERC20;

    let lpToken: ERC20;

    let flashLender: FlashLender;
    let flashBorrower: FlashBorrower;
    let pool: LPool;

    let signerAddress: string;

    beforeEach(async () => {
        borrowApproved = config.approved[1];
        borrowToken = await ethers.getContractAt("ERC20", borrowApproved.address);

        flashLender = await ethers.getContractAt("FlashLender", config.flashLender);
        flashBorrower = await ethers.getContractAt("FlashBorrower", config.flashBorrower);

        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);

        lpToken = await ethers.getContractAt("ERC20", await pool.PTFromLP(borrowToken.address));

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();

        const depositAmount = ethers.BigNumber.from(10).pow(borrowApproved.decimals).mul(10);
        await (await pool.addLiquidity(borrowToken.address, depositAmount)).wait();
    });

    afterEach(async () => {
        const LPTokenAmount = await lpToken.balanceOf(signerAddress);
        if (LPTokenAmount.gt(0)) await (await pool.removeLiquidity(lpToken.address, LPTokenAmount)).wait();
    });

    // It should execute a normal flashloan

    // It should attempt to borrow more than what is available

    // It should fail to repay what is required

    // It should attempt to repay more than what is available
});
