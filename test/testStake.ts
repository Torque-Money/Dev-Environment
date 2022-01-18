import {expect} from "chai";
import {ethers} from "hardhat";
import config from "../config.json";
import {ERC20, LPool} from "../typechain-types";

describe("Stake", async function () {
    let pool: LPool;
    let token: ERC20;
    let signerAddress: string;

    beforeEach(async () => {
        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        token = await ethers.getContractAt("ERC20", config.approved[0].address);

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();
    });

    it("should stake tokens for LP tokens and redeem for an equal amount", async function () {
        const initialBalance = await token.balanceOf(signerAddress);

        const tokensToStake = ethers.BigNumber.from(1000000);
        const stakeValue = await pool.stakeValue(token.address, tokensToStake);
        await pool.stake(token.address, tokensToStake);

        const lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(token.address));

        expect(await token.balanceOf(signerAddress)).to.equal(initialBalance.sub(tokensToStake));
        expect(await lpToken.balanceOf(signerAddress)).to.equal(stakeValue);
        expect(await token.balanceOf(pool.address)).to.equal(tokensToStake);

        expect(await pool.redeemValue(lpToken.address, stakeValue)).to.equal(tokensToStake);

        await pool.redeem(lpToken.address, stakeValue);

        expect(await lpToken.balanceOf(signerAddress)).to.equal(0);
        expect(await token.balanceOf(signerAddress)).to.equal(initialBalance);
    });
});
