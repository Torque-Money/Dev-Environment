import {expect} from "chai";
import hre from "hardhat";
import config from "../config.fork.json";
import {setPrice} from "../scripts/utils/helpers/utilOracle";
import {BIG_NUM, shouldFail} from "../scripts/utils/helpers/utilTest";
import {getLPTokens, getOracleTokens, Token} from "../scripts/utils/helpers/utilTokens";
import {chooseConfig, ConfigType} from "../scripts/utils/utilConfig";
import {IOracle, LPool, LPoolToken} from "../typechain-types";

describe("Oracle", async function () {
    const configType: ConfigType = "fork";
    const config = chooseConfig(configType);

    let oracleTokens: Token[];
    let lpTokens: LPoolToken[];

    let oracle: IOracle;
    let pool: LPool;

    this.beforeAll(async () => {
        const oracleTokens = await getOracleTokens(configType, hre);

        for (const token of oracleTokens.map((token) => token.token)) await setPrice(oracle, token, hre.ethers.BigNumber.from(1));
        oracle = await hre.ethers.getContractAt("IOracle", config.contracts.oracleAddress);

        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);

        lpTokens = await getLPTokens(configType, hre, pool);
    });

    it("should get the prices for accepted tokens", async () => {
        for (const oracleToken of oracleTokens) {
            expect(await oracle.priceMin(oracleToken.token.address, BIG_NUM)).to.not.equal(0);
            expect(await oracle.priceMax(oracleToken.token.address, BIG_NUM)).to.not.equal(0);

            expect(await oracle.amountMin(oracleToken.token.address, BIG_NUM)).to.not.equal(0);
            expect(await oracle.amountMax(oracleToken.token.address, BIG_NUM)).to.not.equal(0);
        }
    });

    it("should get the prices for LP tokens", async () => {
        for (const lpToken of lpTokens) {
            const poolToken = await pool.PTFromLP(lpToken.address);
            await (await pool.provideLiquidity(poolToken, 1)).wait();

            expect(await oracle.priceMin(lpToken.address, BIG_NUM)).to.not.equal(0);
            expect(await oracle.priceMax(lpToken.address, BIG_NUM)).to.not.equal(0);

            expect(await oracle.amountMin(lpToken.address, BIG_NUM)).to.not.equal(0);
            expect(await oracle.amountMax(lpToken.address, BIG_NUM)).to.not.equal(0);

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
