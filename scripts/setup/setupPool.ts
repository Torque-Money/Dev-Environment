import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig} from "../util/chooseConfig";

export default async function main(test: boolean, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(test);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const leveragePool = await hre.ethers.getContractAt("LPool", config.leveragePoolAddress);

    const leveragePoolApprovedTokens = config.approved.filter((approved) => approved.leveragePool).map((approved) => approved.address);
    const approvedNames = config.approved.filter((approved) => approved.leveragePool).map((approved) => config.LPPrefixName + " " + approved.name);
    const approvedSymbols = config.approved.filter((approved) => approved.leveragePool).map((approved) => config.LPPrefixSymbol + approved.symbol);
    await leveragePool.addLPToken(leveragePoolApprovedTokens, approvedNames, approvedSymbols);
    await leveragePool.setApproved(leveragePoolApprovedTokens, Array(leveragePoolApprovedTokens.length).fill(true));

    const maxInterestMinNumerator = Array(leveragePoolApprovedTokens.length).fill(15);
    const maxInterestMinDenominator = Array(leveragePoolApprovedTokens.length).fill(100);
    await leveragePool.setMaxInterestMin(leveragePoolApprovedTokens, maxInterestMinNumerator, maxInterestMinDenominator);

    const maxInterestMaxNumerator = Array(leveragePoolApprovedTokens.length).fill(45);
    const maxInterestMaxDenominator = Array(leveragePoolApprovedTokens.length).fill(100);
    await leveragePool.setMaxInterestMax(leveragePoolApprovedTokens, maxInterestMaxNumerator, maxInterestMaxDenominator);

    const maxUtilizationNumerator = Array(leveragePoolApprovedTokens.length).fill(60);
    const maxUtilizationDenominator = Array(leveragePoolApprovedTokens.length).fill(100);
    await leveragePool.setMaxUtilization(leveragePoolApprovedTokens, maxUtilizationNumerator, maxUtilizationDenominator);

    await leveragePool.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_APPROVED_ROLE")), config.marginLongAddress);
    await leveragePool.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_APPROVED_ROLE")), config.resolverAddress);

    await leveragePool.addTaxAccount(signerAddress);

    console.log("Setup: Leverage pool");
}
