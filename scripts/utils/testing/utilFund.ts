import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../config/utilConfig";
import {getFilteredTokenAddresses} from "../tokens/utilGetTokens";

// Fund account with tokens from the initial amount of starting native coins
export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const USAGE_PERCENT = 70;

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const router = await hre.ethers.getContractAt("UniswapV2Router02", config.setup.converter.routerAddress);

    const weth = await hre.ethers.getContractAt("WETH", config.tokens.wrappedCoin.address);

    const wethAddress = weth.address;
    const addresses = getFilteredTokenAddresses(config, null).filter((address) => address != wethAddress);

    const swapPercentage = 100 * (1 / (addresses.length + 1));
    const availableBalance = (await hre.ethers.provider.getBalance(signerAddress)).mul(USAGE_PERCENT).div(100);
    const swapAmount = availableBalance.mul(swapPercentage).div(100);

    for (const address of addresses) {
        await (await router.swapExactETHForTokens(0, [wethAddress, address], signerAddress, Date.now(), {value: swapAmount})).wait();
        console.log(`Fund: Funded account with ${address}`);
    }

    await (await weth.deposit({value: swapAmount})).wait();
    console.log(`Fund: Funded account with ${weth.address}`);
}
