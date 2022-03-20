import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../config/utilConfig";
import {getFilteredTokenAddresses} from "../tokens/utilGetTokens";
import {getTokenAmounts, getTokensFromAddresses} from "../tokens/utilTokens";

// Clump remaining tokens into native coin
export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const router = await hre.ethers.getContractAt("UniswapV2Router02", config.setup.converter.routerAddress);

    const weth = await hre.ethers.getContractAt("WETH", config.tokens.wrappedCoin.address);

    const wethAddress = weth.address;
    const addresses = getFilteredTokenAddresses(config, null).filter((address) => address != wethAddress);
    addresses.push(wethAddress);

    const tokens = await getTokensFromAddresses(hre, addresses);
    const amounts = await getTokenAmounts(signerAddress, tokens);

    for (let i = 0; i < tokens.length - 1; i++) {
        if (amounts[i].gt(0)) {
            await tokens[i].approve(router.address, hre.ethers.BigNumber.from(2).pow(255));
            await (await router.swapExactTokensForETH(amounts[i], 0, [tokens[i].address, wethAddress], signerAddress, Date.now())).wait();

            console.log(`Clump: Clumped ${tokens[i].address}`);
        }
    }

    await (await weth.withdraw(amounts[amounts.length - 1])).wait();
    console.log(`Clump: Clumped ${wethAddress}`);
}
