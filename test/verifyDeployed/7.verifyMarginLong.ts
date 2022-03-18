import {expect} from "chai";
import hre from "hardhat";
import {expectAddressEqual} from "../../scripts/utils/misc/utilTest";
import {getBorrowTokens, getCollateralTokens} from "../../scripts/utils/misc/utilTokens";

import {chooseConfig} from "../../scripts/utils/config/utilConfig";
import getConfigType from "../../scripts/utils/config/utilConfigTypeSelector";
import {ERC20Upgradeable, MarginLong} from "../../typechain-types";

describe("Verify: MarginLong", () => {
    const configType = getConfigType(hre);
    const config = chooseConfig(configType);

    let collateralTokens: ERC20Upgradeable[];
    let borrowTokens: ERC20Upgradeable[];

    let marginLong: MarginLong;

    before(async () => {
        marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress);

        collateralTokens = await getCollateralTokens(configType, hre);
        borrowTokens = await getBorrowTokens(configType, hre);
    });

    it("should verify the oracle", async () => expectAddressEqual(await marginLong.oracle(), config.contracts.oracleAddress));

    it("should verify the pool", async () => expectAddressEqual(await marginLong.pool(), config.contracts.leveragePoolAddress));

    it("should verify the margin long setup data", async () => {
        expect(await marginLong.minCollateralPrice()).to.equal(config.setup.marginLong.minCollateralPrice);

        const [maxLeverageNumerator, maxLeverageDenominator] = await marginLong.maxLeverage();
        expect(maxLeverageNumerator).to.equal(config.setup.marginLong.maxLeverageNumerator);
        expect(maxLeverageDenominator).to.equal(config.setup.marginLong.maxLeverageDenominator);

        const [liquidationFeePercentNumerator, liquidationFeePercentDenominator] = await marginLong.liquidationFeePercent();
        expect(liquidationFeePercentNumerator).to.equal(config.setup.marginLong.liquidationFeePercentNumerator);
        expect(liquidationFeePercentDenominator).to.equal(config.setup.marginLong.liquidationFeePercentDenominator);
    });

    it("should verify the collateral tokens", async () => {
        for (const token of collateralTokens) {
            expect(await marginLong.isCollateralToken(token.address)).to.equal(true);
            expect(await marginLong.isApprovedCollateralToken(token.address)).to.equal(true);
        }
    });

    it("should verify the borrow tokens", async () => {
        for (const token of borrowTokens) {
            expect(await marginLong.isBorrowToken(token.address)).to.equal(true);
            expect(await marginLong.isApprovedBorrowToken(token.address)).to.equal(true);
        }
    });
});
