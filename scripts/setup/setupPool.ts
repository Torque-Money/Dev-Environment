import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType} from "../utils/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const leveragePool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);

    const leveragePoolApprovedTokens = config.tokens.approved.filter((approved) => approved.leveragePool).map((approved) => approved.address);
    const LPTokens = config.tokens.lpTokens.tokens;
    await (await leveragePool.addLPToken(leveragePoolApprovedTokens, LPTokens)).wait();
    await (await leveragePool.setApproved(leveragePoolApprovedTokens, Array(leveragePoolApprovedTokens.length).fill(true))).wait();

    const TOKEN_ADMIN = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TOKEN_ADMIN_ROLE"));
    for (const lpToken of LPTokens) {
        const LPToken = await hre.ethers.getContractAt("LPoolToken", lpToken);
        await (await LPToken.grantRole(TOKEN_ADMIN, leveragePool.address)).wait();
    }

    const maxInterestMinNumerator = config.tokens.approved.filter((approved) => approved.leveragePool).map((approved) => approved.setup.maxInterestMinNumerator);
    const maxInterestMinDenominator = config.tokens.approved.filter((approved) => approved.leveragePool).map((approved) => approved.setup.maxInterestMinDenominator);
    await (await leveragePool.setMaxInterestMin(leveragePoolApprovedTokens, maxInterestMinNumerator, maxInterestMinDenominator)).wait();

    const maxInterestMaxNumerator = config.tokens.approved.filter((approved) => approved.leveragePool).map((approved) => approved.setup.maxInterestMaxNumerator);
    const maxInterestMaxDenominator = config.tokens.approved.filter((approved) => approved.leveragePool).map((approved) => approved.setup.maxInterestMaxDenominator);
    await (await leveragePool.setMaxInterestMax(leveragePoolApprovedTokens, maxInterestMaxNumerator, maxInterestMaxDenominator)).wait();

    const maxUtilizationNumerator = config.tokens.approved.filter((approved) => approved.leveragePool).map((approved) => approved.setup.maxUtilizationNumerator);
    const maxUtilizationDenominator = config.tokens.approved.filter((approved) => approved.leveragePool).map((approved) => approved.setup.maxUtilizationDenominator);
    await (await leveragePool.setMaxUtilization(leveragePoolApprovedTokens, maxUtilizationNumerator, maxUtilizationDenominator)).wait();

    const POOL_ADMIN = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN_ROLE"));
    await (await leveragePool.grantRole(POOL_ADMIN, config.contracts.marginLongAddress)).wait();
    await (await leveragePool.grantRole(POOL_ADMIN, config.contracts.flashLender)).wait();

    await (await leveragePool.addTaxAccount(config.contracts.timelockAddress)).wait();

    console.log("Setup: LPool");
}
