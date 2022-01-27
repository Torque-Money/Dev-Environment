import {HardhatRuntimeEnvironment} from "hardhat/types";
import {chooseConfig, ConfigType} from "../util/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const converter = await hre.ethers.getContractAt("Converter", config.converterAddress);
    await converter.transferOwnership(config.timelockAddress);

    const pool = await hre.ethers.getContractAt("LPool", config.leveragePoolAddress);
    const POOL_ADMIN_ROLE = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN_ROLE"));
    await pool.grantRole(POOL_ADMIN_ROLE, config.timelockAddress);
    await pool.renounceRole(POOL_ADMIN_ROLE, signerAddress);

    const margin = await hre.ethers.getContractAt("MarginLong", config.marginLongAddress);
    await margin.transferOwnership(config.timelockAddress);

    let oracle;
    if (configType !== "fork") oracle = await hre.ethers.getContractAt("Oracle", config.oracleAddress);
    else oracle = await hre.ethers.getContractAt("OracleTest", config.oracleAddress);
    await oracle.transferOwnership(config.timelockAddress);

    const resolver = await hre.ethers.getContractAt("Resolver", config.resolverAddress);
    await resolver.transferOwnership(config.resolverAddress);

    console.log("Setup: Timelock");
}
