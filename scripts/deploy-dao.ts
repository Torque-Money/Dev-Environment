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
        nonce: transactionCount + 3,
    });

    // Deploy the yield approval
    const yieldApprovalConfig = {
        pool: config.poolAddress,
    };
    const YieldApproval = await hre.ethers.getContractFactory("YieldApproval");
    const yieldApproval = await YieldApproval.deploy(...Object.values(yieldApprovalConfig));
    await yieldApproval.deployed();

    console.log(`Deployed token to ${yieldApproval.address}`);

    // Deploy the token
    const tokenConfig = {
        tokenAmount: (1e18).toString(),
        yieldSlashRate: 10000,
        yieldReward: 2e18,
        yieldApproval: yieldApproval.address,
    };
    const Token = await hre.ethers.getContractFactory("Token");
    const token = await Token.deploy(...Object.values(tokenConfig));
    await token.deployed();

    console.log(`Deployed token to ${token.address}`);

    // Deploy the governor
    const governorConfig = {
        token: token.address,
        timelock: timelockAddress,
        quorumFraction: 2,
        votingDelay: 0,
        votingPeriod: 1,
        proposalThreshold: 0,
    };
    const Governor = await hre.ethers.getContractFactory("DAO");
    const governor = await Governor.deploy(...Object.values(governorConfig));
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
