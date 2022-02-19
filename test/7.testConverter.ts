import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/utils/utilsTest";
import {Converter, ERC20} from "../typechain-types";

describe("Converter", async function () {
    let inApproved: any;
    let inToken: ERC20;

    let outApproved: any;
    let outToken: ERC20;

    let weth: ERC20;

    let converter: Converter;

    let signerAddress: string;

    let swapAmount: BigNumber;
    let wethSwapAmount: BigNumber;

    beforeEach(async () => {
        inApproved = config.approved[0];
        inToken = await ethers.getContractAt("ERC20", inApproved.address);

        outApproved = config.approved[1];
        outToken = await ethers.getContractAt("ERC20", outApproved.address);

        converter = await ethers.getContractAt("Converter", config.converterAddress);

        weth = await ethers.getContractAt("ERC20", await (await ethers.getContractAt("UniswapV2Router02", config.routerAddress)).WETH());
        wethSwapAmount = ethers.BigNumber.from(10).pow(18).mul(1);

        swapAmount = ethers.BigNumber.from(10).pow(inApproved.decimals).mul(1);

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();
    });

    it("should convert one token into another", async () => {
        await shouldFail(async () => await converter.swapMaxTokenOut(inToken.address, swapAmount, inToken.address));

        await (await inToken.approve(converter.address, swapAmount)).wait();

        const initialInAmount = await inToken.balanceOf(signerAddress);
        const initialOutAmount = await outToken.balanceOf(signerAddress);

        await (await converter.swapMaxTokenOut(inToken.address, swapAmount, outToken.address)).wait();

        expect((await inToken.balanceOf(signerAddress)).lt(initialInAmount)).to.equal(true);
        expect((await outToken.balanceOf(signerAddress)).gt(initialOutAmount)).to.equal(true);
    });

    it("should convert WETH to another", async () => {
        await (await weth.approve(converter.address, wethSwapAmount)).wait();

        const initialInAmount = await weth.balanceOf(signerAddress);
        const initialOutAmount = await outToken.balanceOf(signerAddress);

        await (await converter.swapMaxTokenOut(weth.address, wethSwapAmount, outToken.address)).wait();

        expect((await weth.balanceOf(signerAddress)).lt(initialInAmount)).to.equal(true);
        expect((await outToken.balanceOf(signerAddress)).gt(initialOutAmount)).to.equal(true);
    });

    it("should convert another to WETH", async () => {
        await (await inToken.approve(converter.address, swapAmount)).wait();

        const initialInAmount = await inToken.balanceOf(signerAddress);
        const initialOutAmount = await weth.balanceOf(signerAddress);

        await (await converter.swapMaxTokenOut(inToken.address, swapAmount, weth.address)).wait();

        expect((await inToken.balanceOf(signerAddress)).lt(initialInAmount)).to.equal(true);
        expect((await weth.balanceOf(signerAddress)).gt(initialOutAmount)).to.equal(true);
    });

    it("should convert one token into ETH", async () => {
        await (await inToken.approve(converter.address, swapAmount)).wait();

        const initialInAmount = await inToken.balanceOf(signerAddress);
        const initialOutAmount = await ethers.provider.getBalance(signerAddress);

        await converter.swapMaxEthOut(inToken.address, swapAmount);

        expect((await inToken.balanceOf(signerAddress)).lt(initialInAmount)).to.equal(true);
        expect((await ethers.provider.getBalance(signerAddress)).gt(initialOutAmount)).to.equal(true);
    });

    it("should convert WETH into ETH", async () => {
        await (await weth.approve(converter.address, wethSwapAmount)).wait();

        const initialInAmount = await weth.balanceOf(signerAddress);
        const initialOutAmount = await ethers.provider.getBalance(signerAddress);

        await converter.swapMaxEthOut(weth.address, wethSwapAmount);

        expect((await weth.balanceOf(signerAddress)).lt(initialInAmount)).to.equal(true);
        expect((await ethers.provider.getBalance(signerAddress)).gt(initialOutAmount)).to.equal(true);
    });

    it("should swap some ETH into the given token", async () => {
        const initialInAmount = await ethers.provider.getBalance(signerAddress);
        const initialOutAmount = await outToken.balanceOf(signerAddress);

        await (await converter.swapMaxEthIn(outToken.address, {value: 100})).wait();

        expect((await ethers.provider.getBalance(signerAddress)).lt(initialInAmount)).to.equal(true);
        expect((await outToken.balanceOf(signerAddress)).gt(initialOutAmount)).to.equal(true);
    });

    it("should swap some ETH into WETH", async () => {
        const initialInAmount = await ethers.provider.getBalance(signerAddress);
        const initialOutAmount = await weth.balanceOf(signerAddress);

        await (await converter.swapMaxEthIn(weth.address, {value: 100})).wait();

        expect((await ethers.provider.getBalance(signerAddress)).lt(initialInAmount)).to.equal(true);
        expect((await weth.balanceOf(signerAddress)).gt(initialOutAmount)).to.equal(true);
    });
});
