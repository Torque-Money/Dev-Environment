import {getUpgradeableBeaconFactory} from "@openzeppelin/hardhat-upgrades/dist/utils";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import {chooseConfig, ConfigType} from "../utils/config/utilConfig";

export default async function main(configType: ConfigType, hre: HardhatRuntimeEnvironment) {
    const config = chooseConfig(configType);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const converter = await hre.ethers.getContractAt("Converter", config.contracts.converterAddress);
    const CONVERTER_ADMIN = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("CONVERTER_ADMIN_ROLE"));
    await (await converter.grantRole(CONVERTER_ADMIN, config.contracts.timelockAddress)).wait();
    console.log("-- Granted converter admin");
    await (await converter.renounceRole(CONVERTER_ADMIN, signerAddress)).wait();
    console.log("-- Renounced converter admin");

    const pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
    const POOL_ADMIN = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN_ROLE"));
    await (await pool.grantRole(POOL_ADMIN, config.contracts.timelockAddress)).wait();
    console.log("-- Granted pool admin");
    await (await pool.renounceRole(POOL_ADMIN, signerAddress)).wait();
    console.log("-- Renounced pool admin");

    const TOKEN_ADMIN = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TOKEN_ADMIN_ROLE"));
    for (const lpToken of config.tokens.lpTokens.tokens) {
        const LPToken = await hre.ethers.getContractAt("LPoolToken", lpToken);
        await (await LPToken.grantRole(TOKEN_ADMIN, config.contracts.timelockAddress)).wait();
        await (await LPToken.renounceRole(TOKEN_ADMIN, signerAddress)).wait();
        break;
    }
    console.log("-- Granted token admin");
    console.log("-- Renounced token admin");

    const marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress);
    const MARGIN_ADMIN = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("MARGIN_ADMIN_ROLE"));
    await (await marginLong.grantRole(MARGIN_ADMIN, config.contracts.timelockAddress)).wait();
    console.log("-- Granted margin long admin");
    await (await marginLong.renounceRole(MARGIN_ADMIN, signerAddress)).wait();
    console.log("-- Renounced margin long admin");

    let oracle = await hre.ethers.getContractAt("OracleCore", config.contracts.oracleAddress);
    const ORACLE_ADMIN = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("ORACLE_ADMIN_ROLE"));
    await (await oracle.grantRole(ORACLE_ADMIN, config.contracts.timelockAddress)).wait();
    console.log("-- Granted oracle admin");
    await (await oracle.renounceRole(ORACLE_ADMIN, signerAddress)).wait();
    console.log("-- Renounced oracle admin");

    const resolver = await hre.ethers.getContractAt("Resolver", config.contracts.resolverAddress);
    const RESOLVER_ADMIN = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("RESOLVER_ADMIN_ROLE"));
    await (await resolver.grantRole(RESOLVER_ADMIN, config.contracts.timelockAddress)).wait();
    console.log("-- Granted resolver admin");
    await (await resolver.renounceRole(RESOLVER_ADMIN, signerAddress)).wait();
    console.log("-- Renounced resolver admin");

    const flashLender = await hre.ethers.getContractAt("FlashLender", config.contracts.flashLender);
    const FLASHLENDER_ADMIN = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("FLASHLENDER_ADMIN_ROLE"));
    await (await flashLender.grantRole(FLASHLENDER_ADMIN, config.contracts.timelockAddress)).wait();
    console.log("-- Granted flash lender admin");
    await (await flashLender.renounceRole(FLASHLENDER_ADMIN, signerAddress)).wait();
    console.log("-- Renounced flash lender admin");

    await hre.upgrades.admin.transferProxyAdminOwnership(config.contracts.timelockAddress);
    console.log("-- Transferred ownership of proxy admin");

    const beacon = (await getUpgradeableBeaconFactory(hre, hre.ethers.provider.getSigner())).attach(config.tokens.lpTokens.beaconAddress);
    await beacon.transferOwnership(config.contracts.timelockAddress);
    console.log("-- Transferred ownership of token beacon proxy");

    console.log("Setup: Timelock");
}
