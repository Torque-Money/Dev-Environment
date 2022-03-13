import {expect} from "chai";
import hre from "hardhat";

import {ERC20Upgradeable, LPool, OracleTest} from "../../typechain-types";
import {shouldFail} from "../../scripts/utils/helpers/utilTest";
import {getOracleTokens, getBorrowTokens, getTokenAmount, LPFromPT} from "../../scripts/utils/helpers/utilTokens";
import {chooseConfig} from "../../scripts/utils/utilConfig";
import {BigNumber} from "ethers";
import {provideLiquidity, redeemLiquidity} from "../../scripts/utils/helpers/utilPool";
import getConfigType from "../../scripts/utils/utilConfigTypeSelector";
import {BIG_NUM} from "../../scripts/utils/utilConstants";

describe("Interaction: Oracle", () => {
    const configType = getConfigType(hre);
    const config = chooseConfig(configType);

    let oracleTokens: ERC20Upgradeable[];
    let poolTokens: ERC20Upgradeable[];

    let provideAmounts: BigNumber[];

    let oracle: OracleTest;
    let pool: LPool;

    before(async () => {
        oracleTokens = await getOracleTokens(configType, hre);
        poolTokens = await getBorrowTokens(configType, hre);

        provideAmounts = await getTokenAmount(hre, poolTokens);

        oracle = await hre.ethers.getContractAt("OracleTest", config.contracts.oracleAddress);

        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
    });

    it("should get the prices for accepted tokens", async () => {
        for (const token of oracleTokens) {
            expect(await oracle.priceMin(token.address, configType)).to.not.equal(0);
            expect(await oracle.priceMax(token.address, configType)).to.not.equal(0);

            expect(await oracle.amountMin(token.address, configType)).to.not.equal(0);
            expect(await oracle.amountMax(token.address, configType)).to.not.equal(0);
        }
    });

    it("should get the prices for LP tokens", async () => {
        await provideLiquidity(pool, poolTokens, provideAmounts);

        for (const token of poolTokens) {
            const lpToken = await LPFromPT(hre, pool, token);

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
