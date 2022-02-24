import {expect} from "chai";
import {BigNumber} from "ethers";
import hre from "hardhat";

import {Converter} from "../typechain-types";
import {shouldFail} from "../scripts/utils/helpers/utilTest";
import {getCollateralTokens, getPoolTokens, getTokenAmount, Token} from "../scripts/utils/helpers/utilTokens";
import {chooseConfig, ConfigType} from "../scripts/utils/utilConfig";

describe("Converter", async function () {
    const configType: ConfigType = "fork";
    const config = chooseConfig(configType);

    let poolTokens: Token[];
    let collateralTokens: Token[];

    let provideAmounts: BigNumber[];
    let collateralAmounts: BigNumber[];

    let converter: Converter;

    let signerAddress: string;

    // **** There needs to be a nice seemless way of doing this that does not affect the ownership of the tokens or the distribution of the tokens
    // **** This means we will need to swap to and then we will need to swap right back (this is because this cannot be state modifying)

    this.beforeAll(async () => {
        poolTokens = await getPoolTokens(configType, hre);
        collateralTokens = await getCollateralTokens(configType, hre);

        signerAddress = await hre.ethers.provider.getSigner().getAddress();

        converter = await hre.ethers.getContractAt("Converter", config.contracts.converterAddress);
    });

    this.beforeEach(async () => {
        provideAmounts = await getTokenAmount(
            hre,
            poolTokens.map((token) => token.token)
        );

        collateralAmounts = await getTokenAmount(
            hre,
            collateralTokens.map((token) => token.token)
        );
    });

    it("should convert one token into another and back", async () => {
        const index = 0;
        const poolToken = poolTokens.filter((token) => token.token.address != config.tokens.wrappedCoin.address)[index].token;
        const provideAmount = provideAmounts[index];
        const collateralToken = collateralTokens.filter((token) => token.token.address != config.tokens.wrappedCoin.address)[index].token;

        const initialInAmount1 = await poolToken.balanceOf(signerAddress);
        const initialOutAmount1 = await collateralToken.balanceOf(signerAddress);

        await shouldFail(async () => await converter.swapMaxTokenOut(poolToken.address, provideAmount, collateralToken.address));

        const tokensOut = await converter.maxAmountTokenOut(poolToken.address, provideAmount, collateralToken.address);
        await (await converter.swapMaxTokenOut(poolToken.address, provideAmount, collateralToken.address)).wait();

        expect((await poolToken.balanceOf(signerAddress)).lt(initialInAmount1)).to.equal(true);
        expect((await collateralToken.balanceOf(signerAddress)).gt(initialOutAmount1)).to.equal(true);

        const initialInAmount2 = await collateralToken.balanceOf(signerAddress);
        const initialOutAmount2 = await poolToken.balanceOf(signerAddress);

        await (await converter.swapMaxTokenOut(collateralToken.address, tokensOut, poolToken.address)).wait();

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

        await shouldFail(async () => await converter.swapMaxTokenOut(weth.address, wethAmount, collateralToken.address));

        const tokensOut = await converter.maxAmountTokenOut(weth.address, wethAmount, collateralToken.address);
        await (await converter.swapMaxTokenOut(weth.address, wethAmount, collateralToken.address)).wait();

        expect((await weth.balanceOf(signerAddress)).lt(initialInAmount1)).to.equal(true);
        expect((await collateralToken.balanceOf(signerAddress)).gt(initialOutAmount1)).to.equal(true);

        const initialInAmount2 = await collateralToken.balanceOf(signerAddress);
        const initialOutAmount2 = await weth.balanceOf(signerAddress);

        await (await converter.swapMaxTokenOut(collateralToken.address, tokensOut, weth.address)).wait();

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

        const tokensOut = await converter.maxAmountTokenOut(weth.address, wethAmount, collateralToken.address);
        await (await converter.swapMaxEthIn(weth.address, {value: wethAmount})).wait();

        expect((await hre.ethers.provider.getBalance(signerAddress)).lt(initialInAmount1)).to.equal(true);
        expect((await collateralToken.balanceOf(signerAddress)).gt(initialOutAmount1)).to.equal(true);

        const initialInAmount2 = await collateralToken.balanceOf(signerAddress);
        const initialOutAmount2 = await hre.ethers.provider.getBalance(signerAddress);

        await (await converter.swapMaxEthOut(collateralToken.address, tokensOut)).wait();

        expect((await collateralToken.balanceOf(signerAddress)).lt(initialInAmount2)).to.equal(true);
        expect((await hre.ethers.provider.getBalance(signerAddress)).gt(initialOutAmount2)).to.equal(true);
    });

    it("should convert WETH into ETH and back again", async () => {
        const index = 0;
        const weth = await hre.ethers.getContractAt("ERC20", config.tokens.wrappedCoin.address);
        const wethAmount = (await getTokenAmount(hre, [weth]))[0];

        const initialInAmount1 = await weth.balanceOf(signerAddress);
        const initialOutAmount1 = await hre.ethers.provider.getBalance(signerAddress);

        const tokensOut = await converter.maxAmountTokenOut(weth.address, wethAmount, collateralToken.address);
        await (await converter.swapMaxEthIn(weth.address, {value: wethAmount})).wait();
    });
});
