import hre from "hardhat";

import { loadData } from "../../utils";

async function main() {
    const data = loadData();

    const beacon = data.contracts.BeefyLPStrategy.beacon;

    // wFTM, USDC
    const tokens = ["0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83", "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75"];
    const initialAPY = 18.14 * 10 ** 4;
    const uniRouter = "0xF491e7B69E4244ad4002BC14e878a34207E38c29";
    const uniFactory = "0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3";
    const beVault = "0x41D44B276904561Ac51855159516FD4cB2c90968";

    const BeefyLPStrategy = await hre.ethers.getContractFactory("BeefyLPStrategy");
    const beefyLPStrategy = await hre.upgrades.deployBeaconProxy(beacon, BeefyLPStrategy, [tokens, initialAPY, uniRouter, uniFactory, beVault]);
    await beefyLPStrategy.deployed();

    console.log("Deploy | BeefyLPStrategy | Proxy | Proxy:", beefyLPStrategy.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
