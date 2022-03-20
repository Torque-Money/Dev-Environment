import {expect} from "chai";
import hre from "hardhat";

import {ERC20Upgradeable, FlashLender} from "../../typechain-types";

import {chooseConfig} from "../../scripts/utils/config/utilConfig";
import getConfigType from "../../scripts/utils/config/utilConfigTypeSelector";
import {getFilteredTokens} from "../../scripts/utils/tokens/utilGetTokens";

describe("Verify: FlashLend", () => {
    const configType = getConfigType(hre);
    const config = chooseConfig(configType);

    let flashLendToken: ERC20Upgradeable[];

    let flashLender: FlashLender;

    before(async () => {
        flashLender = await hre.ethers.getContractAt("FlashLender", config.contracts.flashLender);

        flashLendToken = await getFilteredTokens(config, hre, "flashLender");
    });

    it("should verify the pool", async () => expect(await flashLender.pool()).to.equal(config.contracts.leveragePoolAddress));

    it("should check all approved tokens", async () => {
        for (const token of flashLendToken) expect(await flashLender.isApproved(token.address)).to.equal(true);
    });
});
