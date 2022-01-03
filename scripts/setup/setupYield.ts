import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const leveragePool = await hre.ethers.getContractAt("LPool", config.leveragePoolAddress);
    const _yield = await hre.ethers.getContractAt("Yield", config.yieldAddress);

    const leveragePoolApprovedTokens = config.approved.filter((approved) => approved.leveragePool).map((approved) => approved.address);
    const lpTokens = await Promise.all(leveragePoolApprovedTokens.map((approved) => leveragePool.LPFromPA(approved)));
    const rateNumerators = Array(lpTokens.length).fill(10);
    const rateDenominators = Array(lpTokens.length).fill(100);
    await _yield.setRates(lpTokens, rateNumerators, rateDenominators);

    console.log("Setup: Yield");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
