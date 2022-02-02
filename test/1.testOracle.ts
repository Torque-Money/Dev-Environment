import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/util/utilsTest";
import {ERC20, OracleTest} from "../typechain-types";

describe("Oracle", async function () {
    let tokenApproved: any;
    let token: ERC20;

    let oracle: OracleTest;

    let lpToken: ERC20;

    let tokenAmount: BigNumber;
    let tokenPrice: BigNumber;

    beforeEach(async () => {
        tokenApproved = config.approved[1];
        token = await ethers.getContractAt("ERC20", tokenApproved.address);

        tokenAmount = ethers.BigNumber.from(10).pow(tokenApproved.decimals).mul(10);

        oracle = await ethers.getContractAt("OracleTest", config.oracleAddress);

        const priceDecimals = await oracle.priceDecimals();
        tokenPrice = ethers.BigNumber.from(10).pow(priceDecimals).mul(30);
        await (await oracle.setPrice(token.address, tokenPrice)).wait();

        const pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(token.address));
    });

    it("should get the prices for the accepted tokens", async () => {
        expect(await oracle.priceMin(token.address, tokenAmount)).to.not.equal(0);
        expect(await oracle.priceMax(token.address, tokenAmount)).to.not.equal(0);

        expect(await oracle.amountMin(token.address, tokenPrice)).to.not.equal(0);
        expect(await oracle.amountMax(token.address, tokenPrice)).to.not.equal(0);
    });

    it("should not work for non accepted tokens", async () => {
        await shouldFail(async () => await oracle.priceMin(lpToken.address, 0));
        await shouldFail(async () => await oracle.priceMax(lpToken.address, 0));

        await shouldFail(async () => await oracle.amountMin(lpToken.address, 0));
        await shouldFail(async () => await oracle.amountMax(lpToken.address, 0));
    });
});
