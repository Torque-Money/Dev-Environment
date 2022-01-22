import {chooseConfig, ConfigType} from "./utilConfig";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import UniswapV2Router02Abi from "../../artifacts/contracts/lib/UniswapV2Router02.sol/UniswapV2Router02.json";
import {UniswapV2Router02} from "../../typechain-types";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const router = new hre.ethers.Contract(config.routerAddress, UniswapV2Router02Abi.abi, signer) as UniswapV2Router02;

    for (const approved of config.approved) {
        const PERCENTAGE = 80;
        const balance = (await hre.ethers.provider.getBalance(signerAddress)).mul(PERCENTAGE).div(100);

        await router.swapExactETHForTokens(0, [await router.WETH(), approved.address], signerAddress, Date.now(), {value: balance.div(config.approved.length)});
    }
}
