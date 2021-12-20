import { ethers, network } from "hardhat";
import config from "../config.json";
import LPool from "../artifacts/contracts/LPool.sol/LPool.json";
import DAO from "../artifacts/contracts/Governor.sol/DAO.json";

describe("DAO", async () => {
    it("Should create a proposal, vote on the proposal, then execute the proposal after the given time", async () => {
        // Initialize the contracts
        const signer = ethers.provider.getSigner();
        const signerAddress = await signer.getAddress();
        const pool = new ethers.Contract(config.poolAddress, LPool.abi, signer);
        const dao = new ethers.Contract(config.governorAddress);

        // **** Eventually integrate the yield and other tokens into this for a full test
    });
});
