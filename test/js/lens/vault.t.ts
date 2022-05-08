import hre from "hardhat";

import { loadData } from "../../../scripts/utils";

async function main() {
    const data = loadData();

    const wrapper = await hre.ethers.getContractAt("VaultETHWrapper", data.contracts.VaultETHWrapper.proxy);
    const vault = await hre.ethers.getContractAt("Vault", data.contracts.Vault.proxies[0]);

    const ftm = await hre.ethers.getContractAt("IERC20Upgradeable", "0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83");
    const usdc = await hre.ethers.getContractAt("IERC20Upgradeable", "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75");

    // Approve the tokens for use with the wrapper
    await ftm.approve(wrapper.address, hre.ethers.constants.MaxUint256);
    await usdc.approve(wrapper.address, hre.ethers.constants.MaxUint256);
    console.log("Approved tokens");

    // Test the deposit

    // Test the withdraw
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
