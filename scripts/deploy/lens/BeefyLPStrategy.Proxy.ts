import hre from "hardhat";

import { loadData } from "../../utils";

async function main() {
    const data = loadData();

    const beacon = data.contracts.BeefyLPStrategyV1.beacon;

    // wFTM, USDC
    const tokens = ["0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83", "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75"];
    const initialAPY = 18.14 * 10 ** 4;
    const uniRouter = "0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52";
    const uniFactory = "0xEF45d134b73241eDa7703fa787148D9C9F4950b0";
    const beVault = "0xA4e2EE5a7fF51224c27C98098D8DB5C770bAAdbE";

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
