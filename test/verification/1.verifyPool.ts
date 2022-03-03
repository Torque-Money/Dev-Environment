import {expect} from "chai";
import hre from "hardhat";
import {getBorrowTokens, LPFromPT} from "../../scripts/utils/helpers/utilTokens";

import {chooseConfig} from "../../scripts/utils/utilConfig";
import getConfigType from "../../scripts/utils/utilConfigTypeSelector";
import {ERC20Upgradeable, LPool, LPoolToken} from "../../typechain-types";

describe("Pool", async function () {
    const configType = await getConfigType(hre);
    const config = chooseConfig(configType);

    let poolTokens: ERC20Upgradeable[];
    let lpTokens: LPoolToken[];

    let pool: LPool;

    this.beforeAll(async () => {
        poolTokens = await getBorrowTokens(configType, hre);

        pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);

        lpTokens = [];
        for (const token of poolTokens) lpTokens.push(await LPFromPT(hre, pool, token));
    });

    it("should verify pool setup state data", async () => {
        const [taxPercentNumerator, taxPercentDenominator] = await pool.taxPercentage();
        expect(taxPercentNumerator).to.equal(config.setup.pool.taxPercentNumerator);
        expect(taxPercentDenominator).to.equal(config.setup.pool.taxPercentDenominator);

        expect(await pool.timePerInterestApplication()).to.equal(config.setup.pool.timePerInterestApplication);
    });

    it("should verify LP tokens", async () => {
        for (const token of poolTokens) {
            const lpToken = await LPFromPT(hre, pool, token);

            expect(await pool.isPT(token.address)).to.equal(true);
            expect(await pool.isApprovedPT(token.address)).to.equal(true);
            expect(await pool.isLP(lpToken.address)).to.equal(true);
            expect(await pool.isApprovedLP(lpToken.address)).to.equal(true);
        }
    });

    it("should verify state of LP tokens", async () => {
        for (const token of poolTokens) {
            const lpToken = await LPFromPT(hre, pool, token);

            expect(await lpToken.name()).to.equal(config.setup.lpToken.LPPrefixName + " " + (await token.name()));
            expect(await lpToken.symbol()).to.equal(config.setup.lpToken.LPPrefixSymbol + (await token.symbol()));
        }
    });
});
