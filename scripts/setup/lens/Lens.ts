import hre from "hardhat";

import { loadData } from "../../utils";

async function main() {
    const data = loadData();

    const lens = await hre.ethers.getContractAt("Lens", data.contracts["LensV2.1"].proxies[0]);
    const caller = await hre.ethers.provider.getSigner().getAddress();

    // Add initial strategies to the lens
    const strategies = data.contracts["BeefyLPStrategyV2.1"].proxies;
    for (const strategy of strategies) {
        await (await lens.add(strategy)).wait();
        console.log(`Setup | Lens | Add strategy '${strategy}' to lens`);
    }

    // Assign the caller as a controller of the lens
    const LENS_CONTROLLER_ROLE = await lens.LENS_CONTROLLER_ROLE();
    await (await lens.grantRole(LENS_CONTROLLER_ROLE, data.contracts.timelock)).wait();
    console.log("Setup | Lens | Assign timelock as lens controller");

    // Assign the registry to the timelock (and revoke)
    const REGISTRY_ADMIN_ROLE = await lens.REGISTRY_ADMIN_ROLE();
    await (await lens.grantRole(REGISTRY_ADMIN_ROLE, data.contracts.timelock)).wait();
    await (await lens.renounceRole(REGISTRY_ADMIN_ROLE, caller)).wait();
    console.log("Setup | Lens | Transfer ownership of registry role");

    // Assign lens admin to the timelock (and revoke)
    const LENS_ADMIN_ROLE = await lens.LENS_ADMIN_ROLE();
    await (await lens.grantRole(LENS_ADMIN_ROLE, data.contracts.timelock)).wait();
    await (await lens.renounceRole(LENS_ADMIN_ROLE, caller)).wait();
    console.log("Setup | Lens | Transfer ownership of admin role");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
