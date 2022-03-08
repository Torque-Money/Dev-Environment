import {expect} from "chai";
import hre from "hardhat";

import {chooseConfig} from "../../scripts/utils/utilConfig";
import getConfigType from "../../scripts/utils/utilConfigTypeSelector";
import {Converter} from "../../typechain-types";

describe("Verify: Converter", async function () {
    const configType = await getConfigType(hre);
    const config = chooseConfig(configType);

    let converter: Converter;

    before(async () => (converter = await hre.ethers.getContractAt("Converter", config.contracts.converterAddress)));

    // **** Problem in here (COULD be to do with a lowercase issue ?)

    it("should verify the router", async () => expect(await converter.router()).to.equal(config.setup.converter.routerAddress));
});
