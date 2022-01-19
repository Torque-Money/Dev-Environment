import {expect} from "chai";
import {ethers} from "hardhat";
import config from "../config.json";
import {ERC20, MarginLong} from "../typechain-types";

describe("MarginLong", async function () {
    let marginLong: MarginLong;
    let token: ERC20;
    let lpToken: ERC20;
    let signerAddress: string;

    beforeEach(async () => {
        marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);
        token = await ethers.getContractAt("ERC20", config.approved[0].address);

        const pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(token.address));

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();
    });

    it("deposit and undeposit collateral into the account", async () => {
        const initialBalance = await token.balanceOf(signerAddress);

        const tokenAmount = ethers.BigNumber.from(1000000);
        await marginLong.addCollateral(token.address, tokenAmount);

        expect(await token.balanceOf(signerAddress)).to.equal(initialBalance.sub(tokenAmount));
        expect(await marginLong.collateral(token.address, signerAddress)).to.equal(tokenAmount);

        expect(await marginLong.totalCollateral(token.address)).to.equal(tokenAmount);
        expect(await token.balanceOf(marginLong.address)).to.equal(tokenAmount);

        await marginLong.removeCollateral(token.address, tokenAmount);

        expect(await token.balanceOf(signerAddress)).to.equal(initialBalance);
        expect(await marginLong.collateral(token.address, signerAddress)).to.equal(0);

        expect(await marginLong.totalCollateral(token.address)).to.equal(0);
        expect(await token.balanceOf(marginLong.address)).to.equal(0);
    });
});
