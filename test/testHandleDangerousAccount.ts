import {expect} from "chai";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/util/utilsTest";

describe("Liquidate", async function () {
    let pool: LPool;
    let token: ERC20;
    let lpToken: ERC20;
    let signerAddress: string;

    beforeEach(async () => {
        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        token = await ethers.getContractAt("ERC20", config.approved[1].address);

        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(token.address));

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();
    });

    it("should liquidate a dangerous account", async () => {});

    it("should reset a dangerous account", async () => {});
});
