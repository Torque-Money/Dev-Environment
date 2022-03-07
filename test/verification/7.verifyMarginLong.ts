import {expect} from "chai";
import hre from "hardhat";
import {getBorrowTokens, getCollateralTokens} from "../../scripts/utils/helpers/utilTokens";

import {chooseConfig} from "../../scripts/utils/utilConfig";
import getConfigType from "../../scripts/utils/utilConfigTypeSelector";
import {ERC20Upgradeable, MarginLong} from "../../typechain-types";

describe("Verify: MarginLong", async function () {
    const configType = await getConfigType(hre);
    const config = chooseConfig(configType);

    let collateralTokens: ERC20Upgradeable[];
    let borrowTokens: ERC20Upgradeable[];

    let marginLong: MarginLong;

    before(async () => {
        marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress);

        collateralTokens = await getCollateralTokens(configType, hre);
        borrowTokens = await getBorrowTokens(configType, hre);
    });

    // **** First we will attempt to verify the other contracts it points to

    it("should verify the task treasury", async () => expect(await resolver.taskTreasury()).to.equal(config.setup.resolver.taskTreasury));

    it("should verify the deposit receiver", async () => expect(await resolver.depositReceiver()).to.equal(resolver.deployTransaction.from));

    it("should verify the eth address", async () => expect(await resolver.ethAddress()).to.equal(config.setup.resolver.ethAddress));

    // **** Next we will verify the tokens it uses

    // **** NOTE: Make sure to go and clean up the rest of the contracts too

    it("should verify the converter address", async () => expect(await resolver.converter()).to.equal(config.contracts.converterAddress));

    it("should verify the margin long address", async () => expect(await resolver.ethAddress()).to.equal(config.contracts.marginLongAddress));
});
