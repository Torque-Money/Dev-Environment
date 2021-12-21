import hre from "hardhat";
import config from "../config.json";
import fs from "fs";
import getFutureAddress from "../utils/getFutureAddress";

async function main() {
    await hre.run("compile");

    // Deploy the governor - deploy directly before the timelock
    const signer = hre.ethers.provider.getSigner();
    const timelockAddress = await getFutureAddress(signer, 1);

    const governorConfig = {
        token: config.tokenAddress,
        timelock: timelockAddress,
        quorumFraction: 4,
        votingDelay: 1,
        votingPeriod: 5,
        proposalThreshold: 0,
    };
    const Governor = await hre.ethers.getContractFactory("DAO");
    const governor = await Governor.deploy(...Object.values(governorConfig));
    await governor.deployed();

    console.log(`Deployed governor to ${governor.address}`);
    config.daoAddress = governor.address;

    fs.writeFileSync("config.json", JSON.stringify(config));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
