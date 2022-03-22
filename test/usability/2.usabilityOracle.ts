import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";

import {ERC20Upgradeable, LPool, OracleTest} from "../../typechain-types";

import {chooseConfig} from "../../scripts/utils/config/utilConfig";
import {provideLiquidity, redeemAllLiquidity} from "../../scripts/utils/protocol/utilPool";
import getConfigType from "../../scripts/utils/config/utilConfigTypeSelector";
import {BIG_NUM} from "../../scripts/utils/config/utilConstants";
import {getFilteredTokens} from "../../scripts/utils/tokens/utilGetTokens";
import {getTokenAmounts, LPFromPT} from "../../scripts/utils/tokens/utilTokens";
import {shouldFail} from "../../scripts/utils/testing/utilTest";

describe("Usability: Oracle", () => {
    const configType = getConfigType(hre);
    const config = chooseConfig(configType);

    let oracleTokens: ERC20Upgradeable[];
    let poolTokens: ERC20Upgradeable[];

    let provideAmounts: BigNumber[];

    let oracle: OracleTest;
    let pool: LPool;

    let signerAddress: string;

    before(async () => {
        signerAddress = await hre.ethers.provider.getSigner().getAddress();

        oracleTokens = await getFilteredTokens(config, hre, "oracle");
        poolTokens = await getFilteredTokens(config, hre, "leveragePool");

        provideAmounts = await getTokenAmounts(signerAddress, poolTokens);

        oracle = await hre.ethers.getContractAt("OracleTest", config.contracts.oracleAddress);

        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
    });

    it("should get the prices for accepted tokens", async () => {
        for (const token of oracleTokens) {
            expect(await oracle.priceMin(token.address, BIG_NUM)).to.not.equal(0);
            expect(await oracle.priceMax(token.address, BIG_NUM)).to.not.equal(0);

            expect(await oracle.amountMin(token.address, BIG_NUM)).to.not.equal(0);
            expect(await oracle.amountMax(token.address, BIG_NUM)).to.not.equal(0);
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

        await redeemAllLiquidity(config, hre, pool);
    });

    it("should not work for non accepted tokens", async () => {
        await shouldFail(async () => await oracle.priceMin(hre.ethers.constants.AddressZero, 0));
        await shouldFail(async () => await oracle.priceMax(hre.ethers.constants.AddressZero, 0));

        await shouldFail(async () => await oracle.amountMin(hre.ethers.constants.AddressZero, 0));
        await shouldFail(async () => await oracle.amountMax(hre.ethers.constants.AddressZero, 0));
    });
});
