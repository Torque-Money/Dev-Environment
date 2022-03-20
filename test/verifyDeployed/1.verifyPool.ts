import {expect} from "chai";
import hre from "hardhat";

import {ERC20Upgradeable, LPool, LPoolToken} from "../../typechain-types";

import {chooseConfig} from "../../scripts/utils/config/utilConfig";
import getConfigType from "../../scripts/utils/config/utilConfigTypeSelector";
import {getFilteredTokens, getLPTokens} from "../../scripts/utils/tokens/utilGetTokens";
import {getApprovedToken, LPFromPT} from "../../scripts/utils/tokens/utilTokens";
import {expectAddressEqual} from "../../scripts/utils/utilTest";

describe("Verify: Pool", () => {
    const configType = getConfigType(hre);
    const config = chooseConfig(configType);

    let poolTokens: ERC20Upgradeable[];
    let lpTokens: LPoolToken[];

    let pool: LPool;

    before(async () => {
        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);

        poolTokens = await getFilteredTokens(config, hre, "leveragePool");
        lpTokens = await getLPTokens(config, hre);
    });

    it("should verify the converter", async () => expect(await pool.converter()).to.equal(config.contracts.converterAddress));

    it("should verify the oracle", async () => expect(await pool.oracle()).to.equal(config.contracts.oracleAddress));

    it("should verify the tax percent", async () => {
        const [taxPercentNumerator, taxPercentDenominator] = await pool.taxPercentage();
        expect(taxPercentNumerator).to.equal(config.setup.pool.taxPercentNumerator);
        expect(taxPercentDenominator).to.equal(config.setup.pool.taxPercentDenominator);
    });

    it("should verify the time per interest application", async () =>
        expect(await pool.timePerInterestApplication()).to.equal(config.setup.pool.timePerInterestApplication));

    it("should verify the max interest min", async () => {
        for (const token of poolTokens) {
            const [maxInterestMinNumerator, maxInterestMinDenominator] = await pool.maxInterestMin(token.address);

            const approved = getApprovedToken(config, token.address);

            expect(maxInterestMinNumerator).to.equal(approved.setup?.maxInterestMinNumerator);
            expect(maxInterestMinDenominator).to.equal(approved.setup?.maxInterestMinDenominator);
        }
    });

    it("should verify the max interest max", async () => {
        for (const token of poolTokens) {
            const [maxInterestMaxNumerator, maxInterestMaxDenominator] = await pool.maxInterestMax(token.address);

            const approved = getApprovedToken(config, token.address);

            expect(maxInterestMaxNumerator).to.equal(approved.setup?.maxInterestMaxNumerator);
            expect(maxInterestMaxDenominator).to.equal(approved.setup?.maxInterestMaxDenominator);
        }
    });

    it("should verify the max utilization", async () => {
        for (const token of poolTokens) {
            const [maxUtilizationNumerator, maxUtilizationDenominator] = await pool.maxUtilization(token.address);

            const approved = getApprovedToken(config, token.address);

            expect(maxUtilizationNumerator).to.equal(approved.setup?.maxUtilizationNumerator);
            expect(maxUtilizationDenominator).to.equal(approved.setup?.maxUtilizationDenominator);
        }
    });

    it("should verify the pool tokens", async () => {
        for (const token of poolTokens) {
            expect(await pool.isPT(token.address)).to.equal(true);
            expect(await pool.isApprovedPT(token.address)).to.equal(true);
        }
    });

    it("should verify the LP tokens", async () => {
        for (const token of lpTokens) {
            expect(await pool.isLP(token.address)).to.equal(true);
            expect(await pool.isApprovedLP(token.address)).to.equal(true);
        }
    });

    it("should verify the metadata of LP tokens", async () => {
        for (const token of poolTokens) {
            const lpToken = await LPFromPT(hre, pool, token);

            const approved = getApprovedToken(config, token.address);
            expect(await lpToken.name()).to.equal(config.setup.lpToken.LPPrefixName + " " + approved.name);
            expect(await lpToken.symbol()).to.equal(config.setup.lpToken.LPPrefixSymbol + approved.symbol);
        }
    });

    it("should verify pool tokens with their respective LP tokens", async () => {
        for (let i = 0; i < poolTokens.length; i++) {
            expectAddressEqual(poolTokens[i].address, await pool.PTFromLP(lpTokens[i].address));
            expectAddressEqual(lpTokens[i].address, await pool.LPFromPT(poolTokens[i].address));
        }
    });
});
