import hre from "hardhat";

import { loadData } from "../../utils";

async function main() {
    const data = loadData();

    const beacon = data.contracts.Vault.beacon;

    // wFTM, USDC
    const tokens = ["0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83", "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75"];
    const strategy = data.contracts.BeefyLPStrategy.proxies[3];
    const feeRecipient = data.contracts.multisig;
    const feePercent = 0;
    const feeDenominator = 100;

    const Vault = await hre.ethers.getContractFactory("Vault");
    const vault = await hre.upgrades.deployBeaconProxy(beacon, Vault, [tokens, strategy, feeRecipient, feePercent, feeDenominator]);
    await vault.deployed();

    console.log("Deploy | Vault | Proxy | Proxy:", vault.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
