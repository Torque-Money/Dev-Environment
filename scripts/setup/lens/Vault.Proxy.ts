import hre from "hardhat";
import { loadData } from "../../utils";

async function main() {
    const data = loadData();

    const vaultV1 = await hre.ethers.getContractAt("TorqueVaultV1", data.contracts.VaultV1.proxies[0]);

    const caller = await hre.ethers.provider.getSigner().getAddress();

    const FEE_ADMIN_ROLE = await vaultV1.FEE_ADMIN_ROLE();
    await (await vaultV1.grantRole(FEE_ADMIN_ROLE, data.contracts.timelock)).wait();
    await (await vaultV1.renounceRole(FEE_ADMIN_ROLE, caller)).wait();
    console.log("Setup Vault: Fee role");

    const EMERGENCY_ADMIN_ROLE = await vaultV1.EMERGENCY_ADMIN_ROLE();
    await (await vaultV1.grantRole(EMERGENCY_ADMIN_ROLE, data.contracts.timelock)).wait();
    await (await vaultV1.renounceRole(EMERGENCY_ADMIN_ROLE, caller)).wait();
    console.log("Setup Vault: Emergency role");

    const VAULT_ADMIN_ROLE = await vaultV1.VAULT_ADMIN_ROLE();
    await (await vaultV1.grantRole(VAULT_ADMIN_ROLE, data.contracts.timelock)).wait();
    await (await vaultV1.renounceRole(VAULT_ADMIN_ROLE, caller)).wait();
    console.log("Setup Vault: Admin role");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
