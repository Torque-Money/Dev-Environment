import { Contract } from "@ethersproject/contracts";
import { expect } from "chai";
import { ethers } from "hardhat";
import config from "../config.json";

describe("Oracle", function () {
    let oracle: Contract;
    let lPool: Contract;

    beforeEach(async () => {
        const LPool = await ethers.getContractFactory("LPool");
        lPool = await LPool.deploy();
        await lPool.deployed();

        const Oracle = await ethers.getContractFactory("Oracle");
        oracle = await Oracle.deploy(config.routerAddress, lPool.address, (1e5).toString());
        await oracle.deployed();
    });

    it("Should return the trade value of two non-pool tokens", async function () {
        const asset1 = "0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E"; // DAI
        const asset2 = "0x841fad6eae12c286d1fd18d1d525dffa75c7effe"; // BOO

        console.log(oracle);
        const value = await oracle.pairValue(asset1, asset2);
        console.log(value);

        // const Greeter = await ethers.getContractFactory("Greeter");
        // const greeter = await Greeter.deploy("Hello, world!");
        // await greeter.deployed();

        // expect(await greeter.greet()).to.equal("Hello, world!");

        // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

        // // wait until the transaction is mined
        // await setGreetingTx.wait();

        // expect(await greeter.greet()).to.equal("Hola, mundo!");
    });
});
