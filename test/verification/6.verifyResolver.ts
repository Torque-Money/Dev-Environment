import hre from "hardhat";
import {expectAddressEqual} from "../../scripts/utils/helpers/utilTest";

import {chooseConfig} from "../../scripts/utils/utilConfig";
import getConfigType from "../../scripts/utils/utilConfigTypeSelector";
import {Resolver} from "../../typechain-types";

describe("Verify: Resolver", async function () {
    const configType = await getConfigType(hre);
    const config = chooseConfig(configType);

    let resolver: Resolver;

    before(async () => {
        resolver = await hre.ethers.getContractAt("Resolver", config.contracts.resolverAddress);
    });

    it("should verify the task treasury", async () => expectAddressEqual(await resolver.taskTreasury(), config.setup.resolver.taskTreasury));

    it("should verify the eth address", async () => expectAddressEqual(await resolver.ethAddress(), config.setup.resolver.ethAddress));

    it("should verify the converter address", async () => expectAddressEqual(await resolver.converter(), config.contracts.converterAddress));

    it("should verify the margin long address", async () => expectAddressEqual(await resolver.marginLong(), config.contracts.marginLongAddress));
});
