import {expect} from "chai";
import hre from "hardhat";
import {getApprovedToken, getBorrowTokens, getLPTokens, LPFromPT} from "../../scripts/utils/protocol/utilTokens";

import {chooseConfig} from "../../scripts/utils/config/utilConfig";
import getConfigType from "../../scripts/utils/config/utilConfigTypeSelector";
import {ERC20Upgradeable, LPool, LPoolToken} from "../../typechain-types";

describe("Verify: Pool", () => {
    const configType = getConfigType(hre);
    const config = chooseConfig(configType);

    let poolTokens: ERC20Upgradeable[];
    let lpTokens: LPoolToken[];

    let pool: LPool;

    before(async () => {
        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);

        poolTokens = await getBorrowTokens(configType, hre);
        lpTokens = await getLPTokens(configType, hre);
    });

    it("should verify the converter", async () => expect(await pool.converter()).to.equal(config.contracts.converterAddress));

    it("should verify the oracle", async () => expect(await pool.oracle()).to.equal(config.contracts.oracleAddress));

    it("should verify the pool setup data", async () => {
        const [taxPercentNumerator, taxPercentDenominator] = await pool.taxPercentage();
        expect(taxPercentNumerator).to.equal(config.setup.pool.taxPercentNumerator);
        expect(taxPercentDenominator).to.equal(config.setup.pool.taxPercentDenominator);

        expect(await pool.timePerInterestApplication()).to.equal(config.setup.pool.timePerInterestApplication);
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

            const approved = getApprovedToken(configType, token.address);
            expect(await lpToken.name()).to.equal(config.setup.lpToken.LPPrefixName + " " + approved.name);
            expect(await lpToken.symbol()).to.equal(config.setup.lpToken.LPPrefixSymbol + approved.symbol);
        }
    });
});
