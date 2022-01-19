import {expect} from "chai";
import {ethers} from "hardhat";
import config from "../config.json";
import {shouldFail} from "../scripts/util/testUtils";
import {ERC20, Oracle} from "../typechain-types";

describe("Oracle", async function () {
    let oracle: Oracle;
    let token: ERC20;
    let lpToken: ERC20;

    beforeEach(async () => {
        oracle = await ethers.getContractAt("Oracle", config.oracleAddress);
        token = await ethers.getContractAt("ERC20", config.approved[0].address);

        const pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(token.address));
    });

    it("should get the prices for the accepted tokens", async () => {
        const tokenAmount = ethers.BigNumber.from(1000000);

        expect(await oracle.priceMin(token.address, tokenAmount)).to.not.equal(0);
        expect(await oracle.priceMax(token.address, tokenAmount)).to.not.equal(0);

        expect(await oracle.amountMin(token.address, tokenAmount)).to.not.equal(0);
        expect(await oracle.amountMax(token.address, tokenAmount)).to.not.equal(0);
    });

    it("should not get the prices of non accepted tokens", async () => {
        await shouldFail(async () => await oracle.priceMin(lpToken.address, 0));
        await shouldFail(async () => await oracle.priceMax(lpToken.address, 0));

        await shouldFail(async () => await oracle.amountMin(lpToken.address, 0));
        await shouldFail(async () => await oracle.amountMax(lpToken.address, 0));
    });
});
