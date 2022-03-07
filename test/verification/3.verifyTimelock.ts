import {expect} from "chai";
import hre from "hardhat";

import {chooseConfig} from "../../scripts/utils/utilConfig";
import getConfigType from "../../scripts/utils/utilConfigTypeSelector";
import {Timelock} from "../../typechain-types";

describe("Verify: Timelock", async function () {
    const configType = await getConfigType(hre);
    const config = chooseConfig(configType);

    let timelock: Timelock;

    before(async () => (timelock = await hre.ethers.getContractAt("Timelock", config.contracts.timelockAddress)));

    it("should verify the proposer", async () => expect(await timelock.hasRole(await timelock.PROPOSER_ROLE(), config.setup.multisig)).to.equal(true));

    it("should verify the executor", async () => expect(await timelock.hasRole(await timelock.EXECUTOR_ROLE(), hre.ethers.constants.AddressZero)).to.equal(true));

    it("should verify the min delay", async () => expect(await timelock.getMinDelay()).to.equal(config.setup.timelock.minDelay));
});
