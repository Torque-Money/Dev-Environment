import ERC20 from "@openzeppelin/contracts/build/contracts/ERC20.json";
import {chooseConfig, ConfigType} from "./chooseConfig";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import UniswapV2Router02 from "../../artifacts/contracts/lib/UniswapV2Router02.sol/UniswapV2Router02.json";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const router = new hre.ethers.Contract(config.routerAddress, UniswapV2Router02.abi, signer);

    for (const approved of config.approved) {
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [approved.whale],
        });
        const tokenSigner = await hre.ethers.getSigner(approved.whale);
        const token = new hre.ethers.Contract(approved.address, ERC20.abi, tokenSigner);

        const tokenBalance = await token.balanceOf(tokenSigner.address);
        await token.transfer(signerAddress, tokenBalance);

        console.log(`Fund: Transferred ${tokenBalance.toString()} of tokens with address ${approved.address} to ${signerAddress}`);
    }
}
