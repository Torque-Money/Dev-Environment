import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {Converter, ERC20} from "../typechain-types";

describe("Converter", async function () {
    let collateralApproved: any;
    let collateralToken: ERC20;

    let borrowedApproved: any;
    let borrowedToken: ERC20;

    let converter: Converter;

    let signerAddress: string;

    let swapAmount: BigNumber;

    beforeEach(async () => {
        collateralApproved = config.approved[0];
        collateralToken = await ethers.getContractAt("ERC20", collateralApproved.address);

        borrowedApproved = config.approved[1];
        borrowedToken = await ethers.getContractAt("ERC20", borrowedApproved.address);

        converter = await ethers.getContractAt("Converter", config.converterAddress);

        swapAmount = ethers.BigNumber.from(10).pow(collateralApproved.decimals).mul(10);

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();
    });

    it("should convert one token into another", async () => {
        await (await collateralToken.approve(converter.address, swapAmount)).wait();

        const initialAmount = await borrowedToken.balanceOf(signerAddress);

        await (await converter.swapMaxTokenOut(collateralToken.address, swapAmount, borrowedToken.address)).wait();

        expect((await borrowedToken.balanceOf(signerAddress)).gt(initialAmount)).to.equal(true);
    });

    it("should convert one token into ETH", async () => {
        await (await collateralToken.approve(converter.address, swapAmount)).wait();

        const initialAmount = await ethers.provider.getBalance(signerAddress);

        await converter.swapMaxEthOut(collateralToken.address, swapAmount);

        expect((await ethers.provider.getBalance(signerAddress)).gt(initialAmount)).to.equal(true);
    });
});
