import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../config/utilConfig";
import {getFilteredTokenAddresses} from "../tokens/utilGetTokens";

// Clump remaining tokens into native coin
export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const router = await hre.ethers.getContractAt("UniswapV2Router02", config.setup.converter.routerAddress);

    const wethAddress = config.tokens.wrappedCoin.address;
    const addresses = getFilteredTokenAddresses(config, null).filter((address) => address != wethAddress);
    addresses.push(wethAddress);

    // **** Possibly switch this one out for the getAmount

    for (const address of addresses) {
        const token = await hre.ethers.getContractAt("ERC20Upgradeable", address);

        const balance = await token.balanceOf(signerAddress);

        if (balance.gt(0)) {
            await token.approve(router.address, hre.ethers.BigNumber.from(2).pow(255));
            await (await router.swapExactTokensForETH(balance, 0, [token.address, wethAddress], signerAddress, Date.now())).wait();

            console.log(`Clump: Clumped ${address}`);
        }
    }
}
