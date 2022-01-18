import {ethers} from "hardhat";
import deployFast from "../scripts/fast";
import config from "../config.json";

describe("Stake", function () {
    beforeEach(async () => await deployFast(false));

    it("should stake tokens for an equal amount of LP tokens", async function () {
        // Do something with the accounts
    });
});
