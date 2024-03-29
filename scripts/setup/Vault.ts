import hre from "hardhat";

import { loadData } from "../utils";

async function main() {
    const data = loadData();

    const lens = data.Lens.proxies[0];
    const vault = await hre.ethers.getContractAt("Vault", data.Vault.proxies[0]);
    const newAdmin = data.timelock;
    const caller = await hre.ethers.provider.getSigner().getAddress();

    // Assign lens as a vault controller
    const VAULT_CONTROLLER_ROLE = await vault.VAULT_CONTROLLER_ROLE();
    await (await vault.grantRole(VAULT_CONTROLLER_ROLE, lens)).wait();
    console.log("Setup | Vault | Assign vault controller to lens");

    const FEE_ADMIN_ROLE = await vault.FEE_ADMIN_ROLE();
    await (await vault.grantRole(FEE_ADMIN_ROLE, newAdmin)).wait();
    await (await vault.renounceRole(FEE_ADMIN_ROLE, caller)).wait();
    console.log("Setup | Vault | Assign fee role");

    const EMERGENCY_ADMIN_ROLE = await vault.EMERGENCY_ADMIN_ROLE();
    await (await vault.grantRole(EMERGENCY_ADMIN_ROLE, newAdmin)).wait();
    await (await vault.renounceRole(EMERGENCY_ADMIN_ROLE, caller)).wait();
    console.log("Setup | Vault | Emergency role");

    const VAULT_ADMIN_ROLE = await vault.VAULT_ADMIN_ROLE();
    await (await vault.grantRole(VAULT_ADMIN_ROLE, newAdmin)).wait();
    await (await vault.renounceRole(VAULT_ADMIN_ROLE, caller)).wait();
    console.log("Setup | Vault | Admin role");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
