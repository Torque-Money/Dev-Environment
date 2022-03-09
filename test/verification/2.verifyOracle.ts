import {expect} from "chai";
import hre from "hardhat";
import {expectAddressEqual} from "../../scripts/utils/helpers/utilTest";
import {getApprovedToken, getOracleTokens} from "../../scripts/utils/helpers/utilTokens";

import {chooseConfig} from "../../scripts/utils/utilConfig";
import getConfigType from "../../scripts/utils/utilConfigTypeSelector";
import {ERC20Upgradeable, OracleLP} from "../../typechain-types";

describe("Verify: Oracle", () => {
    const configType = getConfigType(hre);
    const config = chooseConfig(configType);

    let oracleTokens: ERC20Upgradeable[];

    let oracle: OracleLP;

    before(async () => {
        oracle = await hre.ethers.getContractAt("OracleLP", config.contracts.oracleAddress);

        oracleTokens = await getOracleTokens(configType, hre);
    });

    it("should verify the price decimals", async () => expect(await oracle.priceDecimals()).to.equal(config.setup.oracle.priceDecimals));

    it("should check the configuration of each oracle token", async () => {
        for (const token of oracleTokens) {
            const approved = getApprovedToken(configType, token.address);

            expect(await oracle.isSupported(token.address)).to.equal(true);
            expect(await oracle.decimals(token.address)).to.equal(approved.decimals);
            expectAddressEqual(await oracle.priceFeed(token.address), approved.priceFeed);
        }
    });
});
