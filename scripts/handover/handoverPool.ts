import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const leveragePool = await hre.ethers.getContractAt("LPool", config.leveragePoolAddress);

    await leveragePool.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_APPROVED_ROLE")), config.marginLongAddress);
    await leveragePool.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN_ROLE")), config.timelockAddress);
    await leveragePool.setTaxAccount(config.timelockAddress);
    await leveragePool.renounceRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("POOL_ADMIN_ROLE")), signerAddress);

    console.log("Handover: Leverage pool");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
