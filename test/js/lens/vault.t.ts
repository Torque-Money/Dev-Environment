import hre from "hardhat";

import { loadData } from "../../../scripts/utils";

async function main() {
    const data = loadData();

    const vaultWrapper = await hre.ethers.getContractAt("VaultETHWrapper", data.contracts.VaultETHWrapper.proxy);
    const vault = await hre.ethers.getContractAt("Vault", data.contracts.Vault.proxies[0]);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
