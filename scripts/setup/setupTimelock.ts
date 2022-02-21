import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType} from "../utils/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const converter = await hre.ethers.getContractAt("Converter", config.converterAddress);
    await (await converter.transferOwnership(config.timelockAddress)).wait();

    const pool = await hre.ethers.getContractAt("LPool", config.leveragePoolAddress);
    const POOL_ADMIN_ROLE = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN_ROLE"));
    await (await pool.grantRole(POOL_ADMIN_ROLE, config.timelockAddress)).wait();
    await (await pool.renounceRole(POOL_ADMIN_ROLE, signerAddress)).wait();

    const margin = await hre.ethers.getContractAt("MarginLong", config.marginLongAddress);
    await (await margin.transferOwnership(config.timelockAddress)).wait();

    let oracle;
    if (configType !== "fork") oracle = await hre.ethers.getContractAt("Oracle", config.oracleAddress);
    else oracle = await hre.ethers.getContractAt("OracleTest", config.oracleAddress);
    await (await oracle.transferOwnership(config.timelockAddress)).wait();

    const resolver = await hre.ethers.getContractAt("Resolver", config.resolverAddress);
    await (await resolver.transferOwnership(config.timelockAddress)).wait();

    const flashLender = await hre.ethers.getContractAt("FlashLender", config.flashLender);
    await (await flashLender.transferOwnership(config.timelockAddress)).wait();

    // **** Do not forget the token roles - make sure to clear cache before deploying on testnet or mainnet

    await hre.upgrades.admin.transferProxyAdminOwnership(config.timelockAddress);

    console.log("Setup: Timelock");
}
