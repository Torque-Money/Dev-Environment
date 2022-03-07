import {expect} from "chai";
import hre from "hardhat";
import {getApprovedToken, getBorrowTokens, getLPTokens, LPFromPT} from "../../scripts/utils/helpers/utilTokens";

import {chooseConfig} from "../../scripts/utils/utilConfig";
import getConfigType from "../../scripts/utils/utilConfigTypeSelector";
import {ERC20Upgradeable, LPool, LPoolToken} from "../../typechain-types";

describe("Verify: Pool", async function () {
    const configType = await getConfigType(hre);
    const config = chooseConfig(configType);

    let poolTokens: ERC20Upgradeable[];
    let lpTokens: LPoolToken[];

    let pool: LPool;

    before(async () => {
        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);

        poolTokens = await getBorrowTokens(configType, hre);
        lpTokens = await getLPTokens(configType, hre);
    });

    it("should verify pool setup state data", async () => {
        const [taxPercentNumerator, taxPercentDenominator] = await pool.taxPercentage();
        expect(taxPercentNumerator).to.equal(config.setup.pool.taxPercentNumerator);
        expect(taxPercentDenominator).to.equal(config.setup.pool.taxPercentDenominator);

        expect(await pool.timePerInterestApplication()).to.equal(config.setup.pool.timePerInterestApplication);
    });

    it("should verify pool tokens", async () => {
        for (const token of poolTokens) {
            expect(await pool.isPT(token.address)).to.equal(true);
            expect(await pool.isApprovedPT(token.address)).to.equal(true);
        }
    });

    it("should verify LP tokens", async () => {
        for (const token of lpTokens) {
            expect(await pool.isLP(token.address)).to.equal(true);
            expect(await pool.isApprovedLP(token.address)).to.equal(true);
        }
    });

    it("should verify state of LP tokens", async () => {
        for (const token of poolTokens) {
            const lpToken = await LPFromPT(hre, pool, token);

            const approved = getApprovedToken(configType, token.address);
            expect(await lpToken.name()).to.equal(config.setup.lpToken.LPPrefixName + " " + approved.name);
            expect(await lpToken.symbol()).to.equal(config.setup.lpToken.LPPrefixSymbol + approved.symbol);
        }
    });
});
