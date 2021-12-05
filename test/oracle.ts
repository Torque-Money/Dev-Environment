import { ethers } from "hardhat";
import config from "../config.json";
import ERC20Abi from "@openzeppelin/contracts/build/contracts/ERC20.json";

describe("Oracle", () => {
    it("Should deploy the pool and oracle, approve the assets for the pool, and get the value of the assets from the oracle", async () => {
        const DECIMALS = 1e5;
        const assets = [config.daiAddress, config.booAddress];
        const poolAssets: string[] = []; // waDAI, waBOO

        // Deploy pool
        const LPool = await ethers.getContractFactory("LPool");
        const lPool = await LPool.deploy();
        await lPool.deployed();

        // Deploy oracle
        const Oracle = await ethers.getContractFactory("Oracle");
        const oracle = await Oracle.deploy(config.routerAddress, lPool.address, DECIMALS.toString());
        await oracle.deployed();

        // Approve assets for pool
        await lPool.approveAsset(assets[0], "Wabbit Dai", "waDAI");
        await lPool.approveAsset(assets[1], "Wabbit Boo", "waBOO");
        const poolAsset1 = await lPool.getPoolToken(assets[0]);
        const poolAsset2 = await lPool.getPoolToken(assets[1]);
        poolAssets.push(poolAsset1);
        poolAssets.push(poolAsset2);
        console.log(`Approved assets ${assets} that correspond to pool tokens ${poolAssets}`);

        // Get the price of asset 1 against asset2
        const value = await oracle.pairValue(assets[0], assets[1]);
        const result = value.toNumber() / DECIMALS;
        console.log(`Value: ${result}`);

        // Now we want to deposit tokens to the pool an get the conversion rates of the pool
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [config.daiWhale],
        });
        const signer = await ethers.getSigner(config.daiWhale);
        const dai = new ethers.Contract(config.daiAddress, ERC20Abi.abi, signer);
        console.log(await dai.balanceOf(signer.address));
    });
});
