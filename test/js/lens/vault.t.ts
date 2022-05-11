import hre from "hardhat";

import { Vault, VaultETHWrapper } from "../../../typechain-types/src/lens/vault";

import { loadData } from "../../../scripts/utils";

async function main() {
    const data = loadData();
    const caller = await hre.ethers.provider.getSigner().getAddress();

    const wrapper = (await hre.ethers.getContractAt("VaultETHWrapper", data.contracts.VaultETHWrapper.proxy)) as VaultETHWrapper;
    const vault = (await hre.ethers.getContractAt("Vault", data.contracts.Vault.proxies[0])) as Vault;

    const ftm = await hre.ethers.getContractAt("IERC20Upgradeable", "0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83");
    const usdc = await hre.ethers.getContractAt("IERC20Upgradeable", "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75");

    // Approve the tokens for use with the wrapper
    await ftm.approve(wrapper.address, hre.ethers.constants.MaxUint256);
    await usdc.approve(wrapper.address, hre.ethers.constants.MaxUint256);
    console.log("Test | Vault | Approved tokens");

    const initialFTM = await hre.ethers.provider.getSigner().getBalance();
    const initialwFTM = await ftm.balanceOf(caller);
    const initialUSDC = await usdc.balanceOf(caller);
    console.log("Test | Vault | Initial FTM:", initialFTM.toString());
    console.log("Test | Vault | Initial wFTM:", initialwFTM.toString());
    console.log("Test | Vault | Initial USDC:", initialUSDC.toString());

    // Test the deposit
    const amount = [hre.ethers.BigNumber.from(10).pow(18), hre.ethers.BigNumber.from(10).pow(6)];
    await wrapper.deposit(vault.address, amount, { value: amount[0] });
    console.log("Test | Vault | Deposited");

    // Test the withdraw
    await vault.approve(wrapper.address, hre.ethers.constants.MaxUint256);

    const shares = await vault.balanceOf(caller);
    console.log("Test | Vault | Shares:", shares.toString());
    await vault.redeem(shares);
    // await wrapper.redeem(vault.address, shares); // **** There is some sort of problem with this - but what is the problem ?
    console.log("Test | Vault | Redeemed");

    const finalFTM = await hre.ethers.provider.getSigner().getBalance();
    const finalwFTM = await ftm.balanceOf(caller);
    const finalUSDC = await usdc.balanceOf(caller);
    console.log("Test | Vault | Final FTM:", finalFTM.toString());
    console.log("Test | Vault | Final wFTM:", finalwFTM.toString());
    console.log("Test | Vault | Final USDC:", finalUSDC.toString());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
