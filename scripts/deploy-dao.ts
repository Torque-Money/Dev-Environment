import { getContractAddress } from "ethers/lib/utils";
import hre from "hardhat";

async function main() {
    await hre.run("compile");

    const tokenAmount = (1e18).toString();
    const Token = await hre.ethers.getContractFactory("Token");
    const token = await Token.deploy(tokenAmount);
    await token.deployed();

    console.log(`Deployed token to ${token.address}`);

    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();
    const transactionCount = await signer.getTransactionCount();
    const timelockAddress = getContractAddress({
        from: signerAddress,
        nonce: transactionCount + 1,
    });
    const Governor = await hre.ethers.getContractFactory("DAO");
    const governor = await Governor.deploy(token.address, timelockAddress);
    await governor.deployed();

    console.log(`Deployed governor to ${governor.address}`);

    const Timelock = await hre.ethers.getContractFactory("TimelockController");
    const timelock = await Timelock.deploy(2, [signerAddress], [signerAddress]);
    await timelock.deployed();

    console.log(`Deployed timelock to ${timelock.address}`);

    console.log("Attempting to create a proposal...");

    const transferCallData = token.interface.encodeFunctionData("transfer", [signerAddress, 0]);
    await governor["propose(address[],uint256[],bytes[],string)"]([token.address], [0], [transferCallData], "Proposal #1: Give grant (worth 0) to owner");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
