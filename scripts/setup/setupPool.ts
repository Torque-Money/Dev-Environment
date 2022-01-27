import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType} from "../util/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const leveragePool = await hre.ethers.getContractAt("LPool", config.leveragePoolAddress);

    const leveragePoolApprovedTokens = config.approved.filter((approved) => approved.leveragePool).map((approved) => approved.address);
    const approvedNames = config.approved.filter((approved) => approved.leveragePool).map((approved) => config.LPPrefixName + " " + approved.name);
    const approvedSymbols = config.approved.filter((approved) => approved.leveragePool).map((approved) => config.LPPrefixSymbol + approved.symbol);
    await leveragePool.addLPToken(leveragePoolApprovedTokens, approvedNames, approvedSymbols);
    await leveragePool.setApproved(leveragePoolApprovedTokens, Array(leveragePoolApprovedTokens.length).fill(true));

    const maxInterestMinNumerator = config.approved.filter((approved) => approved.leveragePool).map((approved) => approved.setup.maxInterestMinNumerator);
    const maxInterestMinDenominator = config.approved.filter((approved) => approved.leveragePool).map((approved) => approved.setup.maxInterestMinDenominator);
    await leveragePool.setMaxInterestMin(leveragePoolApprovedTokens, maxInterestMinNumerator, maxInterestMinDenominator);

    const maxInterestMaxNumerator = config.approved.filter((approved) => approved.leveragePool).map((approved) => approved.setup.maxInterestMaxNumerator);
    const maxInterestMaxDenominator = config.approved.filter((approved) => approved.leveragePool).map((approved) => approved.setup.maxInterestMaxDenominator);
    await leveragePool.setMaxInterestMax(leveragePoolApprovedTokens, maxInterestMaxNumerator, maxInterestMaxDenominator);

    const maxUtilizationNumerator = config.approved.filter((approved) => approved.leveragePool).map((approved) => approved.setup.maxUtilizationNumerator);
    const maxUtilizationDenominator = config.approved.filter((approved) => approved.leveragePool).map((approved) => approved.setup.maxUtilizationDenominator);
    await leveragePool.setMaxUtilization(leveragePoolApprovedTokens, maxUtilizationNumerator, maxUtilizationDenominator);

    const POOL_APPROVED_ROLE = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_APPROVED_ROLE"));
    await leveragePool.grantRole(POOL_APPROVED_ROLE, config.marginLongAddress);
    await leveragePool.grantRole(POOL_APPROVED_ROLE, config.resolverAddress);

    await leveragePool.addTaxAccount(config.timelockAddress);

    console.log("Setup: Leverage pool");
}
