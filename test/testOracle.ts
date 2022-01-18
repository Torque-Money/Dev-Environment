import {expect} from "chai";
import {ethers} from "hardhat";
import config from "../config.json";
import {shouldFail} from "../scripts/util/testUtils";
import {ERC20, Oracle} from "../typechain-types";

describe("Stake", async function () {
    let oracle: Oracle;
    let token: ERC20;
    let lpToken: ERC20;
    let signerAddress: string;

    beforeEach(async () => {
        oracle = await ethers.getContractAt("Oracle", config.oracleAddress);
        token = await ethers.getContractAt("ERC20", config.approved[0].address);

        const pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(token.address));

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();
    });

    it("should get the prices and decimals of the given tokens", async () => {});
});
