import {expect} from "chai";
import hre from "hardhat";
import {getFlashLenderTokens} from "../../scripts/utils/helpers/utilTokens";

import {chooseConfig} from "../../scripts/utils/utilConfig";
import getConfigType from "../../scripts/utils/utilConfigTypeSelector";
import {ERC20Upgradeable, FlashLender} from "../../typechain-types";

describe("Verify: FlashLend", async function () {
    const configType = await getConfigType(hre);
    const config = chooseConfig(configType);

    let flashLendToken: ERC20Upgradeable[];

    let flashLender: FlashLender;

    before(async () => {
        flashLender = await hre.ethers.getContractAt("FlashLender", config.contracts.flashLender);

        flashLendToken = await getFlashLenderTokens(configType, hre);
    });

    it("should verify the pool", async () => expect(await flashLender.pool()).to.equal(config.contracts.leveragePoolAddress));

    it("should check all approved tokens", async () => {
        for (const token of flashLendToken) expect(await flashLender.isApproved(token.address)).to.equal(true);
    });
});
