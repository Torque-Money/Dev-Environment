import ERC20 from "@openzeppelin/contracts/build/contracts/ERC20.json";
import {chooseConfig, ConfigType} from "./utilChooseConfig";
import {HardhatRuntimeEnvironment} from "hardhat/types";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    for (const approved of config.approved) {
        const token = new hre.ethers.Contract(approved.address, ERC20.abi, signer);
        const tokenBalance = await token.balanceOf(signerAddress);

        await token.approve(config.leveragePoolAddress, tokenBalance);
        await token.approve(config.marginLongAddress, tokenBalance);

        console.log(`Approve: Approved contracts to spend ${tokenBalance.toString()} tokens with address ${approved.address}`);
    }
}
