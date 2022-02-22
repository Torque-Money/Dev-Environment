import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/utils/helpers/utilTest";
import {getOracleTokens, getTokenAmounts} from "../scripts/utils/helpers/utilTokens";
import {ERC20, IOracle} from "../typechain-types";

describe("Oracle", async function () {
    let tokenApproved: any[];
    let token: ERC20[];
    let tokenAmount: BigNumber;
    let lpToken: ERC20;

    let oracle: IOracle;

    let tokenPrice: BigNumber;

    // **** I also need to test it with the pool

    beforeEach(async () => {
        const token = await getOracleTokens("fork", hre);
        const tokenAmounts = await getTokenAmounts(hre, token);

        oracle = await hre.ethers.getContractAt("IOracle", config.oracleAddress);

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
