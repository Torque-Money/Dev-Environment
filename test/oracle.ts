import { ethers } from "hardhat";
import config from "../config.json";
import ERC20Abi from "@openzeppelin/contracts/build/contracts/ERC20.json";

describe("Oracle", () => {
    it("Should deploy the pool and oracle, approve the assets for the pool, and get the value of the assets from the oracle", async () => {
        const DECIMALS = 1e5;

        // Deploy pool
        const LPool = await ethers.getContractFactory("LPool");
        const lPool = await LPool.deploy();
        await lPool.deployed();

        // Deploy oracle
        const Oracle = await ethers.getContractFactory("Oracle");
        const oracle = await Oracle.deploy(config.routerAddress, lPool.address, DECIMALS.toString());
        await oracle.deployed();

        // Approve assets for pool
        await lPool.approveAsset(config.daiAddress, "Wabbit Dai", "waDAI");
        await lPool.approveAsset(config.booAddress, "Wabbit Boo", "waBOO");

        const waDAIAddress = await lPool.getPoolToken(config.daiAddress);
        const waBOOAddress = await lPool.getPoolToken(config.booAddress);

        const waDAI = new ethers.Contract(waDAIAddress, ERC20Abi.abi, ethers.provider.getSigner());
        const waBOO = new ethers.Contract(waBOOAddress, ERC20Abi.abi, ethers.provider.getSigner());
        console.log(`DAI and BOO correspond to pool tokens ${waDAIAddress}, ${waBOOAddress} respectively`);

        // Get the price of asset 1 against asset2
        const value = await oracle.pairValue(config.daiAddress, config.booAddress);
        const result = value.toNumber() / DECIMALS;
        console.log(`Value: ${result}`);

        // Impersonate a DAI whale and deposit using it
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [config.daiWhale],
        });
        const signer = await ethers.getSigner(config.daiWhale);

        // Deposit DAI into the pool in exchange for pool tokens
        const lPoolDaiWhale = lPool.connect(signer);
        const dai = new ethers.Contract(config.daiAddress, ERC20Abi.abi, signer);

        const depositAmount = 1e18;
        await dai.approve(lPool.address, (1e18).toString());
        await lPoolDaiWhale.deposit(config.daiAddress, depositAmount.toString());

        // Get the balance of pool tokens for the depositor
        const waDAIBal = await waDAI.balanceOf(config.daiWhale);
        console.log(`waDAI balance of DAI whale after deposit: ${waDAIBal}`);
    });
});
