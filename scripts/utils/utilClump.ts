import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "./config/utilConfig";

// Clump remaining tokens into native coin
export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const router = await hre.ethers.getContractAt("UniswapV2Router02", config.setup.converter.routerAddress);
    const weth = await hre.ethers.getContractAt("WETH", config.tokens.wrappedCoin.address);

    for (const approved of config.tokens.approved.filter((approved) => approved.address != weth.address)) {
        const token = await hre.ethers.getContractAt("ERC20Upgradeable", approved.address);
        const balance = await token.balanceOf(signerAddress);
        if (balance.gt(0)) {
            await token.approve(router.address, hre.ethers.BigNumber.from(2).pow(255));
            await (await router.swapExactTokensForETH(balance, 0, [token.address, weth.address], signerAddress, Date.now())).wait();

            console.log(`Clump: Clumped ${approved.address}`);
        }
    }

    const wethToken = await hre.ethers.getContractAt("ERC20Upgradeable", weth.address);
    const wethAmount = await wethToken.balanceOf(signerAddress);
    await (await weth.withdraw(wethAmount)).wait();
    console.log(`Clump: Clumped ${weth.address}`);
}
