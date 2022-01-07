import hre from "hardhat";
import config from "../../config.json";

export default async function main() {
    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();

    const token = await hre.ethers.getContractAt("Token", config.tokenAddress);

    await token.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TOKEN_ADMIN_ROLE")), config.timelockAddress);
    await token.grantRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TOKEN_MINTER_ROLE")), config.reserveAddress);
    await token.renounceRole(hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TOKEN_ADMIN_ROLE")), signerAddress);

    console.log("Handover: Token");
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
