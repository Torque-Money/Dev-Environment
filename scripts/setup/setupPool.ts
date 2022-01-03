import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const leveragePool = await hre.ethers.getContractAt("LPool", config.leveragePoolAddress);

    const leveragePoolApprovedTokens = config.approved.filter((approved) => approved.leveragePool).map((approved) => approved.address);
    const approvedNames = config.approved.map((approved) => "Torque Leveraged " + approved.name);
    const approvedSymbols = config.approved.map((approved) => "tl" + approved.symbol);
    await leveragePool.approve(leveragePoolApprovedTokens, approvedNames, approvedSymbols);
    const maxInterestMinNumerator = Array(leveragePoolApprovedTokens.length).fill(15);
    const maxInterestMinDenominator = Array(leveragePoolApprovedTokens.length).fill(100);
    await leveragePool.setMaxInterestMin(leveragePoolApprovedTokens, maxInterestMinNumerator, maxInterestMinDenominator);
    const maxInterestMaxNumerator = Array(leveragePoolApprovedTokens.length).fill(45);
    const maxInterestMaxDenominator = Array(leveragePoolApprovedTokens.length).fill(100);
    await leveragePool.setMaxInterestMax(leveragePoolApprovedTokens, maxInterestMaxNumerator, maxInterestMaxDenominator);
    const maxUtilizationNumerator = Array(leveragePoolApprovedTokens.length).fill(60);
    const maxUtilizationDenominator = Array(leveragePoolApprovedTokens.length).fill(100);
    await leveragePool.setMaxUtilization(leveragePoolApprovedTokens, maxUtilizationNumerator, maxUtilizationDenominator);

    await leveragePool.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_APPROVED_ROLE")), config.isolatedMarginAddress);
    await leveragePool.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN_ROLE")), config.timelockAddress);
    await leveragePool.setTaxAccount(config.timelockAddress);
    await leveragePool.renounceRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN_ROLE")), signerAddress);
    console.log("Setup: Leverage pool");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
