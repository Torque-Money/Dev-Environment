import { Contract } from "@ethersproject/contracts";
import { expect } from "chai";
import { ethers } from "hardhat";
import config from "../config.json";

describe("Oracle", function () {
    let oracle: Contract;
    let lPool: Contract;
    const decimals = 1e5;

    const assets = ["0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E", "0x841fad6eae12c286d1fd18d1d525dffa75c7effe"]; // DAI, BOO
    const poolAssets: string[] = []; // waDAI, waBOO

    beforeEach(async () => {
        const LPool = await ethers.getContractFactory("LPool");
        lPool = await LPool.deploy();
        await lPool.deployed();

        const Oracle = await ethers.getContractFactory("Oracle");
        oracle = await Oracle.deploy(config.routerAddress, lPool.address, decimals.toString());
        await oracle.deployed();
    });

    it("Should approve the asset pairs for the pool and get the pool tokens", async () => {
        await lPool.approveAsset(assets[0], "Wabbit Dai", "waDAI");
        await lPool.approveAsset(assets[1], "Wabbit Boo", "waBOO");

        const poolAsset1 = await lPool.getPoolToken(assets[0]);
        const poolAsset2 = await lPool.getPoolToken(assets[1]);
        poolAssets.push(poolAsset1);
        poolAssets.push(poolAsset2);

        console.log(`Approved assets ${assets} that correspond to pool tokens ${poolAssets}`);
    });

    it("Should return the trade value of two non-pool tokens", async () => {
        const value = await oracle.pairValue(assets[0], assets[1]);
        const result = value.toNumber() / decimals;
        console.log(`Value: ${result}`);
    });
});
