import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";
import config from "../config.fork.json";
import {setPrice} from "../scripts/utils/helpers/utilOracle";
import {shouldFail} from "../scripts/utils/helpers/utilTest";
import {getLPTokens, getOracleTokens, getTokenAmount, Token} from "../scripts/utils/helpers/utilTokens";
import {IOracle, LPool, LPoolToken} from "../typechain-types";

describe("Oracle", async function () {
    let oracleTokens: Token[];
    let oracleTokenAmounts: BigNumber[];
    let lpTokens: LPoolToken[];

    let oracle: IOracle;
    let pool: LPool;

    let tokenPrice: BigNumber = hre.ethers.BigNumber.from(100);

    beforeEach(async () => {
        const oracleTokens = await getOracleTokens("fork", hre);
        const oracleTokenAmounts = await getTokenAmount(
            hre,
            oracleTokens.map((token) => token.token)
        );

        oracle = await hre.ethers.getContractAt("IOracle", config.contracts.oracleAddress);
        for (const token of oracleTokens.map((token) => token.token)) await setPrice(oracle, token, hre.ethers.BigNumber.from(30));

        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
        lpTokens = await getLPTokens("fork", hre, pool);
    });

    it("should get the prices for the accepted tokens", async () => {
        for (let i = 0; i < oracleTokens.length; i++) {
            expect(await oracle.priceMin(oracleTokens[i].token.address, oracleTokenAmounts[i])).to.not.equal(0);
            expect(await oracle.priceMax(oracleTokens[i].token.address, oracleTokenAmounts[i])).to.not.equal(0);

            expect(await oracle.amountMin(oracleTokens[i].token.address, tokenPrice)).to.not.equal(0);
            expect(await oracle.amountMax(oracleTokens[i].token.address, tokenPrice)).to.not.equal(0);
        }
    });

    it("should get the prices for LP tokens", async () => {
        // **** First we need to stake some tokens and then we need to unstake them ?

        for (let i = 0; i < oracleTokens.length; i++) {
            expect(await oracle.priceMin(oracleTokens[i].token.address, oracleTokenAmounts[i])).to.not.equal(0);
            expect(await oracle.priceMax(oracleTokens[i].token.address, oracleTokenAmounts[i])).to.not.equal(0);

            expect(await oracle.amountMin(oracleTokens[i].token.address, tokenPrice)).to.not.equal(0);
            expect(await oracle.amountMax(oracleTokens[i].token.address, tokenPrice)).to.not.equal(0);
        }
    });

    it("should not work for non accepted tokens", async () => {
        await shouldFail(async () => await oracle.priceMin(hre.ethers.constants.AddressZero, 0));
        await shouldFail(async () => await oracle.priceMax(hre.ethers.constants.AddressZero, 0));

        await shouldFail(async () => await oracle.amountMin(hre.ethers.constants.AddressZero, 0));
        await shouldFail(async () => await oracle.amountMax(hre.ethers.constants.AddressZero, 0));
    });
});
