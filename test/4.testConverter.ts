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

    it("should convert one token into another", async () => {
        const index = 0;
        const poolToken = poolTokens[index].token;
        const provideAmount = provideAmounts[index];
        const collateralToken = collateralTokens[index].token;
        const collateralAmount = collateralAmounts[index];

        // **** At the end of this we need to convert them all back

        // **** We can estimate how much of the other token it will swap into and then we can unswap it
        // **** How do we determine what token it should indeed be swapped into though and that it will not overlap ?

        await shouldFail(async () => await converter.swapMaxTokenOut(poolToken.address, provideAmount, collateralToken.address));

        const initialInAmount = await inToken.balanceOf(signerAddress);
        const initialOutAmount = await outToken.balanceOf(signerAddress);

        // **** First I need to track how much comes out of the coverter, then I need to unswap that at the end for the original token

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
