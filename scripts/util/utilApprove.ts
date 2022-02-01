import ERC20Abi from "@openzeppelin/contracts/build/contracts/ERC20.json";
import {chooseConfig, ConfigType} from "./utilConfig";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {ERC20} from "../../typechain-types";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();

    for (const approved of config.approved) {
        const token = new hre.ethers.Contract(approved.address, ERC20Abi.abi, signer) as ERC20;

        const approvedAmount = hre.ethers.BigNumber.from(2).pow(255);

        await token.approve(config.leveragePoolAddress, approvedAmount);
        await token.approve(config.marginLongAddress, approvedAmount);

        console.log(`Approve: Approved contracts to spend tokens with address ${approved.address}`);
    }
}
