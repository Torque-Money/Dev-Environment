import {ethers} from "hardhat";
import config from "../config.json";
import {LPool} from "../typechain-types";

describe("Stake", async function () {
    let pool: LPool;

    beforeEach(async () => (pool = await ethers.getContractAt("LPool", config.leveragePoolAddress)));

    it("should stake tokens for an equal amount of LP tokens", async function () {});
});
