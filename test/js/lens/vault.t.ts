import hre from "hardhat";

import { Vault, VaultETHWrapper } from "../../../typechain-types/src/lens/vault";

import { loadData } from "../../../scripts/utils";

async function main() {
    const data = loadData();

    const wrapper = (await hre.ethers.getContractAt("VaultETHWrapper", data.contracts.VaultETHWrapper.proxy)) as VaultETHWrapper;
    const vault = (await hre.ethers.getContractAt("Vault", data.contracts.Vault.proxies[0])) as Vault;

    const ftm = await hre.ethers.getContractAt("IERC20Upgradeable", "0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83");
    const usdc = await hre.ethers.getContractAt("IERC20Upgradeable", "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75");

    // Approve the tokens for use with the wrapper
    await ftm.approve(wrapper.address, hre.ethers.constants.MaxUint256);
    await usdc.approve(wrapper.address, hre.ethers.constants.MaxUint256);

    await ftm.approve(vault.address, hre.ethers.constants.MaxUint256);
    await usdc.approve(vault.address, hre.ethers.constants.MaxUint256);

    console.log("Test | Vault | Approved tokens");

    // Test the deposit

    // **** Something is wrong in here - we are not approving the correct balances or something ??? We need to test what failed and why (COULD be a setup error)

    const amount = [1, 1];
    // await wrapper.deposit(vault.address, amount);
    await vault.deposit(amount);
    console.log("Test | Vault | Deposited");

    // Test the withdraw
    const caller = await hre.ethers.provider.getSigner().getAddress();

    await vault.approve(wrapper.address, hre.ethers.constants.MaxUint256);

    const shares = await vault.balanceOf(caller);
    await wrapper.redeem(vault.address, shares);
    console.log("Test | Vault | Redeemed");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
