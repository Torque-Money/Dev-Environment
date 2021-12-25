import hre from "hardhat";
import config from "../config.json";
import fs from "fs";
import getFutureAddress from "../utils/getFutureAddress";

export default async function main() {
    // Deploy the governor - deploy directly before the timelock
    const signer = hre.ethers.provider.getSigner();
    const timelockAddress = await getFutureAddress(signer, 1);

    const blocktime = hre.ethers.BigNumber.from(2); // Seconds
    const governanceConfig = {
        token: config.tokenAddress,
        timelock: timelockAddress,
        quorumFraction: 6,
        votingDelay: hre.ethers.BigNumber.from(86400).div(blocktime),
        votingPeriod: hre.ethers.BigNumber.from(604800).div(blocktime),
        proposalThreshold: 2,
    };
    const Governance = await hre.ethers.getContractFactory("Governance");
    const governance = await Governance.deploy(...Object.values(governanceConfig));
    await governance.deployed();

    console.log(`Deployed governor to ${governance.address}`);
    config.governanceAddress = governance.address;

    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
