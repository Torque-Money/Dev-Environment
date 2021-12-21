import { ethers, network } from "hardhat";
import ERC20Votes from "@openzeppelin/contracts/build/contracts/ERC20Votes.json";
import ERC20 from "@openzeppelin/contracts/build/contracts/ERC20.json";
import LPool from "../artifacts/contracts/LPool.sol/LPool.json";
import config from "../config.json";

describe("Yield", async () => {
    it("Should stake tokens, reap yield, unstake tokens", async () => {
        // ======== Initialize the contracts ========
        const signer = ethers.provider.getSigner();
        const signerAddress = await signer.getAddress();
        const testToken = new ethers.Contract(config.approved[0].address, ERC20.abi, signer);
        const token = new ethers.Contract(config.tokenAddress, ERC20Votes.abi, signer);
        const pool = new ethers.Contract(config.poolAddress, LPool.abi, signer);

        //======== Stake tokens ========

        //======== Yield reward ========

        //======== Unstake tokens reward ========
    });
});
