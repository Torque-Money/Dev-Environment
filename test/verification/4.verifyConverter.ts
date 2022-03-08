import hre from "hardhat";
import {expectAddressEqual} from "../../scripts/utils/helpers/utilTest";

import {chooseConfig} from "../../scripts/utils/utilConfig";
import getConfigType from "../../scripts/utils/utilConfigTypeSelector";
import {Converter} from "../../typechain-types";

describe("Verify: Converter", async function () {
    const configType = await getConfigType(hre);
    const config = chooseConfig(configType);

    let converter: Converter;

    before(async () => (converter = await hre.ethers.getContractAt("Converter", config.contracts.converterAddress)));

    it("should verify the router", async () => expectAddressEqual(await converter.router(), config.setup.converter.routerAddress));
});
