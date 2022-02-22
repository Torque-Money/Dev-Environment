import {expect} from "chai";
import hre from "hardhat";
import config from "../config.fork.json";
import {setPrice} from "../scripts/utils/helpers/utilOracle";
import {shouldFail} from "../scripts/utils/helpers/utilTest";
import {getLPTokens, getOracleTokens, Token} from "../scripts/utils/helpers/utilTokens";
import {IOracle, LPool, LPoolToken} from "../typechain-types";

describe("Oracle", async function () {
    let oracleTokens: Token[];
    let lpTokens: LPoolToken[];

    let oracle: IOracle;
    let pool: LPool;

    let bigNum = hre.ethers.BigNumber.from(10).pow(255);

    this.beforeAll(async () => {
        const oracleTokens = await getOracleTokens("fork", hre);

        for (const token of oracleTokens.map((token) => token.token)) await setPrice(oracle, token, hre.ethers.BigNumber.from(1));
        oracle = await hre.ethers.getContractAt("IOracle", config.contracts.oracleAddress);

        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);

        lpTokens = await getLPTokens("fork", hre, pool);
    });

    it("should get the prices for accepted tokens", async () => {
        for (const oracleToken of oracleTokens) {
            expect(await oracle.priceMin(oracleToken.token.address, bigNum)).to.not.equal(0);
            expect(await oracle.priceMax(oracleToken.token.address, bigNum)).to.not.equal(0);

            expect(await oracle.amountMin(oracleToken.token.address, bigNum)).to.not.equal(0);
            expect(await oracle.amountMax(oracleToken.token.address, bigNum)).to.not.equal(0);
        }
    });

    it("should get the prices for LP tokens", async () => {
        for (const lpToken of lpTokens) {
            const poolToken = await pool.PTFromLP(lpToken.address);
            await (await pool.provideLiquidity(poolToken, 1)).wait();

            expect(await oracle.priceMin(lpToken.address, bigNum)).to.not.equal(0);
            expect(await oracle.priceMax(lpToken.address, bigNum)).to.not.equal(0);

            expect(await oracle.amountMin(lpToken.address, bigNum)).to.not.equal(0);
            expect(await oracle.amountMax(lpToken.address, bigNum)).to.not.equal(0);

            await (await pool.redeemLiquidity(lpToken.address, 1)).wait();
        }
    });

    it("should not work for non accepted tokens", async () => {
        await shouldFail(async () => await oracle.priceMin(hre.ethers.constants.AddressZero, 0));
        await shouldFail(async () => await oracle.priceMax(hre.ethers.constants.AddressZero, 0));

        await shouldFail(async () => await oracle.amountMin(hre.ethers.constants.AddressZero, 0));
        await shouldFail(async () => await oracle.amountMax(hre.ethers.constants.AddressZero, 0));
    });
});
