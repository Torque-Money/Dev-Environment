import hre from "hardhat";

import { loadData } from "../../utils";

async function main() {
    const data = loadData();

    const vault = await hre.ethers.getContractAt("Vault", data.contracts["VaultV2.0"].proxies[0]);
    const strategy = await hre.ethers.getContractAt("BeefyLPStrategy", data.contracts["BeefyLPStrategyV2.0"].proxies[0]);
    const caller = await hre.ethers.provider.getSigner().getAddress();

    // Assign the vault as a controller of the strategy
    const STRATEGY_CONTROLLER_ROLE = await strategy.STRATEGY_CONTROLLER_ROLE();
    await (await strategy.grantRole(STRATEGY_CONTROLLER_ROLE, vault.address)).wait();
    console.log("Setup | BeefyLPStrategy | Assign vault as strategy controller");

    // // Assign the emergency to the timelock (and revoke)
    // const EMERGENCY_ADMIN_ROLE = await strategy.EMERGENCY_ADMIN_ROLE();
    // await (await strategy.grantRole(EMERGENCY_ADMIN_ROLE, data.contracts.timelock)).wait();
    // await (await strategy.renounceRole(EMERGENCY_ADMIN_ROLE, caller)).wait();
    // console.log("Setup | BeefyLPStrategy | Transfer ownership of emergency role");

    // // Assign strategy admin to the timelock (and revoke)
    // const STRATEGY_ADMIN_ROLE = await strategy.STRATEGY_ADMIN_ROLE();
    // await (await strategy.grantRole(STRATEGY_ADMIN_ROLE, data.contracts.timelock)).wait();
    // await (await strategy.renounceRole(STRATEGY_ADMIN_ROLE, caller)).wait();
    // console.log("Setup | BeefyLPStrategy | Transfer ownership of admin role");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
