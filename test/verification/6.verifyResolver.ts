import {expect} from "chai";
import hre from "hardhat";
import {getFlashLenderTokens} from "../../scripts/utils/helpers/utilTokens";

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

    it("should verify the task treasury", async () => expect(await resolver.taskTreasury()).to.equal(config.setup.resolver.taskTreasury));

    it("should verify the deposit receiver", async () => expect(await resolver.depositReceiver()).to.equal(resolver.deployTransaction.from));

    it("should verify the eth address", async () => expect(await resolver.ethAddress()).to.equal(config.setup.resolver.ethAddress));

    it("should verify the converter address", async () => expect(await resolver.converter()).to.equal(config.contracts.converterAddress));

    it("should verify the margin long address", async () => expect(await resolver.ethAddress()).to.equal(config.contracts.marginLongAddress));
});
