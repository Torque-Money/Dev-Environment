import {expect} from "chai";
import hre from "hardhat";

import {LPool, OracleTest} from "../typechain-types";
import {setPrice} from "../scripts/utils/helpers/utilOracle";
import {BIG_NUM, BORROW_PRICE, shouldFail} from "../scripts/utils/helpers/utilTest";
import {getOracleTokens, getPoolTokens, getTokenAmount, LPFromPT, Token} from "../scripts/utils/helpers/utilTokens";
import {chooseConfig, ConfigType} from "../scripts/utils/utilConfig";
import {BigNumber} from "ethers";
import {provideLiquidity, redeemLiquidity} from "../scripts/utils/helpers/utilPool";

describe("Oracle", async function () {
    const configType: ConfigType = "fork";
    const config = chooseConfig(configType);

    let oracleTokens: Token[];
    let poolTokens: Token[];

    let provideAmounts: BigNumber[];

    let oracle: OracleTest;
    let pool: LPool;

    this.beforeAll(async () => {
        oracleTokens = await getOracleTokens(configType, hre);
        poolTokens = await getPoolTokens(configType, hre);

        provideAmounts = await getTokenAmount(
            hre,
            poolTokens.map((token) => token.token)
        );

        oracle = await hre.ethers.getContractAt("OracleTest", config.contracts.oracleAddress);
        for (const token of oracleTokens.map((token) => token.token)) await setPrice(oracle, token, BORROW_PRICE);

        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
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
        await provideLiquidity(
            pool,
            poolTokens.map((token) => token.token),
            provideAmounts
        );

        for (const token of poolTokens) {
            const lpToken = await LPFromPT(hre, pool, token.token);

            expect(await oracle.priceMin(lpToken.address, BIG_NUM)).to.not.equal(0);
            expect(await oracle.priceMax(lpToken.address, BIG_NUM)).to.not.equal(0);

            expect(await oracle.amountMin(lpToken.address, BIG_NUM)).to.not.equal(0);
            expect(await oracle.amountMax(lpToken.address, BIG_NUM)).to.not.equal(0);
        }

        await redeemLiquidity(configType, hre, pool);
    });

    it("should not work for non accepted tokens", async () => {
        await shouldFail(async () => await oracle.priceMin(hre.ethers.constants.AddressZero, 0));
        await shouldFail(async () => await oracle.priceMax(hre.ethers.constants.AddressZero, 0));

        await shouldFail(async () => await oracle.amountMin(hre.ethers.constants.AddressZero, 0));
        await shouldFail(async () => await oracle.amountMax(hre.ethers.constants.AddressZero, 0));
    });
});
