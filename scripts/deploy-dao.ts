import { getContractAddress } from "ethers/lib/utils";
import hre from "hardhat";
import config from "../config.json";

async function main() {
    await hre.run("compile");

    // Calculate the addresses of the contracts
    const signer = hre.ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();
    const transactionCount = await signer.getTransactionCount();

    const timelockAddress = getContractAddress({
        from: signerAddress,
        nonce: transactionCount + 2,
    });

    // Deploy the yield approval
    const YieldApproval = await hre.ethers.getContractFactory("YieldApproval");
    const yieldApproval = await YieldApproval.deploy();
    await yieldApproval.deployed();

    console.log(`Deployed token to ${yieldApproval.address}`);

    // Deploy the token
    const tokenAmount = (1e18).toString();
    const Token = await hre.ethers.getContractFactory("Token");
    const token = await Token.deploy(tokenAmount);
    await token.deployed();

    console.log(`Deployed token to ${token.address}`);

    // Deploy the governor
    const Governor = await hre.ethers.getContractFactory("DAO");
    const governor = await Governor.deploy(token.address, timelockAddress);
    await governor.deployed();

    console.log(`Deployed governor to ${governor.address}`);

    // Deploy the timelock
    const Timelock = await hre.ethers.getContractFactory("TimelockController");
    const timelock = await Timelock.deploy(2, [signerAddress], [signerAddress]);
    await timelock.deployed();

    console.log(`Deployed timelock to ${timelock.address}`);

    // Test the DAO
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
