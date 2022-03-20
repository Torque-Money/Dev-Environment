import hre from "hardhat";

import {Converter} from "../../typechain-types";

import {chooseConfig} from "../../scripts/utils/config/utilConfig";
import getConfigType from "../../scripts/utils/config/utilConfigTypeSelector";
import {expectAddressEqual} from "../../scripts/utils/utilTest";

describe("Verify: Converter", () => {
    const configType = getConfigType(hre);
    const config = chooseConfig(configType);

    let converter: Converter;

    before(async () => (converter = await hre.ethers.getContractAt("Converter", config.contracts.converterAddress)));

    it("should verify the router", async () => expectAddressEqual(await converter.router(), config.setup.converter.routerAddress));
});
