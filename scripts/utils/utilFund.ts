import {chooseConfig, ConfigType} from "./utilConfig";
import {HardhatRuntimeEnvironment} from "hardhat/types";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const router = await hre.ethers.getContractAt("UniswapV2Router02", config.setup.routerAddress);
    const weth = await hre.ethers.getContractAt("WETH", config.tokens.wrappedCoin.address);

    const initialBalance = await hre.ethers.provider.getBalance(signerAddress);
    const PERCENTAGE = 60;
    const swapBalance = initialBalance.mul(PERCENTAGE).div(100);
    for (const approved of config.tokens.approved)
        await (
            await router.swapExactETHForTokens(0, [weth.address, approved.address], signerAddress, Date.now(), {value: swapBalance.div(config.tokens.approved.length)})
        ).wait();

    const wethAmount = initialBalance.mul(Math.floor((100 - 60) / 2)).div(100);
    await (await weth.deposit({value: wethAmount})).wait();
}
