import {expect} from "chai";
import hre from "hardhat";

import {Converter} from "../typechain-types";
import {shouldFail} from "../scripts/utils/helpers/utilTest";
import {getCollateralTokens, getPoolTokens, getTokenAmount, Token} from "../scripts/utils/helpers/utilTokens";
import {chooseConfig, ConfigType} from "../scripts/utils/utilConfig";
import {BigNumber} from "ethers";

describe("Converter", async function () {
    const configType: ConfigType = "fork";
    const config = chooseConfig(configType);

    let poolToken: Token;
    let collateralToken: Token;
    let weth: Token[];

    let provideAmount: BigNumber;
    let wethAmount: BigNumber;

    let converter: Converter;

    let signerAddress: string;

    this.beforeAll(async () => {
        poolToken = (await getPoolTokens(configType, hre)).filter((token) => token.token.address != config.tokens.wrappedCoin.address)[0];
        collateralToken = (await getCollateralTokens(configType, hre)).filter((token) => token.token.address != config.tokens.wrappedCoin.address)[0];
        weth = await hre.ethers.getContractAt("ERC20", config.tokens.wrappedCoin.address);

        const wethAmount = (await getTokenAmount(hre, [weth]))[0];

        signerAddress = await hre.ethers.provider.getSigner().getAddress();

        converter = await hre.ethers.getContractAt("Converter", config.contracts.converterAddress);
    });

    it("should convert one token into another and back", async () => {
        const index = 0;
        const provideAmount = (await getTokenAmount(hre, [poolToken]))[0];

        const initialInAmount1 = await poolToken.balanceOf(signerAddress);
        const initialOutAmount1 = await collateralToken.balanceOf(signerAddress);

        const tokensOut = await converter.maxAmountTokenInTokenOut(poolToken.address, provideAmount, collateralToken.address);
        await (await converter.swapMaxTokenInTokenOut(poolToken.address, provideAmount, collateralToken.address)).wait();

        expect((await poolToken.balanceOf(signerAddress)).lt(initialInAmount1)).to.equal(true);
        expect((await collateralToken.balanceOf(signerAddress)).gt(initialOutAmount1)).to.equal(true);

        const initialInAmount2 = await collateralToken.balanceOf(signerAddress);
        const initialOutAmount2 = await poolToken.balanceOf(signerAddress);

        await (await converter.swapMaxTokenInTokenOut(collateralToken.address, tokensOut, poolToken.address)).wait();

        expect((await collateralToken.balanceOf(signerAddress)).lt(initialInAmount2)).to.equal(true);
        expect((await poolToken.balanceOf(signerAddress)).gt(initialOutAmount2)).to.equal(true);
    });

    it("should convert WETH to another and back again", async () => {
        const index = 0;
        const weth = await hre.ethers.getContractAt("ERC20", config.tokens.wrappedCoin.address);
        const wethAmount = (await getTokenAmount(hre, [weth]))[0];
        const collateralToken = collateralTokens.filter((token) => token.token.address != config.tokens.wrappedCoin.address)[index].token;

        const initialInAmount1 = await weth.balanceOf(signerAddress);
        const initialOutAmount1 = await collateralToken.balanceOf(signerAddress);

        await shouldFail(async () => await converter.swapMaxTokenInTokenOut(weth.address, wethAmount, collateralToken.address));

        const tokensOut = await converter.maxAmountTokenInTokenOut(weth.address, wethAmount, collateralToken.address);
        await (await converter.swapMaxTokenInTokenOut(weth.address, wethAmount, collateralToken.address)).wait();

        expect((await weth.balanceOf(signerAddress)).lt(initialInAmount1)).to.equal(true);
        expect((await collateralToken.balanceOf(signerAddress)).gt(initialOutAmount1)).to.equal(true);

        const initialInAmount2 = await collateralToken.balanceOf(signerAddress);
        const initialOutAmount2 = await weth.balanceOf(signerAddress);

        await (await converter.swapMaxTokenInTokenOut(collateralToken.address, tokensOut, weth.address)).wait();

        expect((await collateralToken.balanceOf(signerAddress)).lt(initialInAmount2)).to.equal(true);
        expect((await weth.balanceOf(signerAddress)).gt(initialOutAmount2)).to.equal(true);
    });

    it("should convert ETH to another and back again", async () => {
        const index = 0;
        const weth = await hre.ethers.getContractAt("ERC20", config.tokens.wrappedCoin.address);
        const wethAmount = (await getTokenAmount(hre, [weth]))[0];
        const collateralToken = collateralTokens.filter((token) => token.token.address != config.tokens.wrappedCoin.address)[index].token;

        const initialInAmount1 = await hre.ethers.provider.getBalance(signerAddress);
        const initialOutAmount1 = await collateralToken.balanceOf(signerAddress);

        const tokensOut = await converter.maxAmountTokenInTokenOut(weth.address, wethAmount, collateralToken.address);
        await (await converter.swapMaxEthInTokenOut(collateralToken.address, {value: wethAmount})).wait();

        expect((await hre.ethers.provider.getBalance(signerAddress)).lt(initialInAmount1)).to.equal(true);
        expect((await collateralToken.balanceOf(signerAddress)).gt(initialOutAmount1)).to.equal(true);

        const initialInAmount2 = await collateralToken.balanceOf(signerAddress);
        const initialOutAmount2 = await hre.ethers.provider.getBalance(signerAddress);

        await (await converter.swapMaxTokenInEthOut(collateralToken.address, tokensOut)).wait();

        expect((await collateralToken.balanceOf(signerAddress)).lt(initialInAmount2)).to.equal(true);
        expect((await hre.ethers.provider.getBalance(signerAddress)).gt(initialOutAmount2)).to.equal(true);
    });

    it("should convert WETH into ETH and back again", async () => {
        const weth = await hre.ethers.getContractAt("ERC20", config.tokens.wrappedCoin.address);
        const wethAmount = (await getTokenAmount(hre, [weth]))[0];

        const initialInAmount1 = await weth.balanceOf(signerAddress);
        const initialOutAmount1 = await hre.ethers.provider.getBalance(signerAddress);

        await (await converter.swapMaxTokenInEthOut(weth.address, wethAmount)).wait();

        expect((await weth.balanceOf(signerAddress)).lt(initialInAmount1)).to.equal(true);
        expect((await hre.ethers.provider.getBalance(signerAddress)).gt(initialOutAmount1)).to.equal(true);

        const initialInAmount2 = await hre.ethers.provider.getBalance(signerAddress);
        const initialOutAmount2 = await weth.balanceOf(signerAddress);

        await (await converter.swapMaxEthInTokenOut(weth.address, {value: wethAmount})).wait();

        expect((await hre.ethers.provider.getBalance(signerAddress)).lt(initialInAmount2)).to.equal(true);
        expect((await weth.balanceOf(signerAddress)).gt(initialOutAmount2)).to.equal(true);
    });
});
