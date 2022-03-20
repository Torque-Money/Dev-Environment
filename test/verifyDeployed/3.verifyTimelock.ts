import {expect} from "chai";
import hre from "hardhat";

import {Timelock} from "../../typechain-types";

import {chooseConfig} from "../../scripts/utils/config/utilConfig";
import getConfigType from "../../scripts/utils/config/utilConfigTypeSelector";

describe("Verify: Timelock", () => {
    const configType = getConfigType(hre);
    const config = chooseConfig(configType);

    let timelock: Timelock;

    before(async () => (timelock = await hre.ethers.getContractAt("Timelock", config.contracts.timelockAddress)));

    it("should verify the proposer", async () => {
        if (config.contracts.multisig) expect(await timelock.hasRole(await timelock.PROPOSER_ROLE(), config.contracts.multisig)).to.equal(true);
    });

    it("should verify the executor", async () => expect(await timelock.hasRole(await timelock.EXECUTOR_ROLE(), hre.ethers.constants.AddressZero)).to.equal(true));

    it("should verify the min delay", async () => expect(await timelock.getMinDelay()).to.equal(config.setup.timelock.minDelay));
});
