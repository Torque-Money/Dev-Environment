import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {Converter, ERC20} from "../typechain-types";

describe("Converter", async function () {
    let inApproved: any;
    let inToken: ERC20;

    let outApproved: any;
    let outToken: ERC20;

    let converter: Converter;

    let signerAddress: string;

    let swapAmount: BigNumber;

    beforeEach(async () => {
        inApproved = config.approved[0];
        inToken = await ethers.getContractAt("ERC20", inApproved.address);

        outApproved = config.approved[1];
        outToken = await ethers.getContractAt("ERC20", outApproved.address);

        converter = await ethers.getContractAt("Converter", config.converterAddress);

        swapAmount = ethers.BigNumber.from(10).pow(inApproved.decimals).mul(1);

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();
    });

    it("should convert one token into another", async () => {
        await (await inToken.approve(converter.address, swapAmount)).wait();

        const initialAmount = await outToken.balanceOf(signerAddress);

        await (await converter.swapMaxTokenOut(inToken.address, swapAmount, outToken.address)).wait();

        expect((await outToken.balanceOf(signerAddress)).gt(initialAmount)).to.equal(true);
    });

    it("should convert one token into ETH", async () => {
        await (await inToken.approve(converter.address, swapAmount)).wait();

        const initialAmount = await ethers.provider.getBalance(signerAddress);

        await converter.swapMaxEthOut(inToken.address, swapAmount);

        expect((await ethers.provider.getBalance(signerAddress)).gt(initialAmount)).to.equal(true);
    });

    it("should swap some ETH into the given token", async () => {
        const initialAmount = await outToken.balanceOf(signerAddress);

        await (await converter.swapMaxEthIn(outToken.address, {value: 100})).wait();

        expect((await outToken.balanceOf(signerAddress)).gt(initialAmount)).to.equal(true);
    });
});
