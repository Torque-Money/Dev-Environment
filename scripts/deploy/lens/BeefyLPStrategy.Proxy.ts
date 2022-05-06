import hre from "hardhat";

import { loadData } from "../../utils";

async function main() {
    const data = loadData();

    const beacon = data.contracts["BeefyLPStrategyV2.0"].beacon;

    // wFTM, USDC
    const tokens = ["0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83", "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75"];

    // // Beefy USDC-FTM LP SushiSwap
    // const uniRouter = "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506";
    // const uniFactory = "0xc35DADB65012eC5796536bD9864eD8773aBc74C4";
    // const beVault = "0xb870e4755C737D2753D7298D0e70344077905Ed5";

    // // Beefy USDC-FTM LP SpiritSwap
    // const uniRouter = "0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52";
    // const uniFactory = "0xEF45d134b73241eDa7703fa787148D9C9F4950b0";
    // const beVault = "0xA4e2EE5a7fF51224c27C98098D8DB5C770bAAdbE";

    // // Beefy USDC-FTM LP WigoSwap
    // const uniRouter = "0x5023882f4D1EC10544FCB2066abE9C1645E95AA0";
    // const uniFactory = "0xC831A5cBfb4aC2Da5ed5B194385DFD9bF5bFcBa7";
    // const beVault = "0x70c6AF9Dff8C19B3db576E5E199B22A883874f05";

    // Beefy USDC-FTM LP SpookySwap
    const uniRouter = "0xF491e7B69E4244ad4002BC14e878a34207E38c29";
    const uniFactory = "0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3";
    const beVault = "0x41D44B276904561Ac51855159516FD4cB2c90968";

    const BeefyLPStrategy = await hre.ethers.getContractFactory("BeefyLPStrategy");
    const beefyLPStrategy = await hre.upgrades.deployBeaconProxy(beacon, BeefyLPStrategy, [tokens, uniRouter, uniFactory, beVault]);
    await beefyLPStrategy.deployed();

    console.log("Deploy | BeefyLPStrategy | Proxy | Proxy:", beefyLPStrategy.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
