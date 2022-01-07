import hre, {ethers} from "hardhat";
import fs from "fs";
import {getContractAddress} from "ethers/lib/utils";
import config from "../../config.json";

export default async function main() {
    const signer = hre.ethers.provider.getSigner();
    const transactionCount = await signer.getTransactionCount();
    const timelockAddress = getContractAddress({
        from: await signer.getAddress(),
        nonce: transactionCount + 1,
    });

    const constructorArgsGovernance = {
        token: config.tokenAddress,
        timelockAddress: timelockAddress,
        quorumFraction: 6,
        votingDelay: hre.ethers.BigNumber.from(86400).div(config.avgBlockTime),
        votingPeriod: hre.ethers.BigNumber.from(604800).div(config.avgBlockTime),
        proposalThreshold: 2,
    };
    const Governance = await hre.ethers.getContractFactory("Governance");
    const governance = await Governance.deploy(...Object.values(constructorArgsGovernance));
    config.governanceAddress = governance.address;
    console.log("Deployed: Governance");

    const constructorArgsTimelock = {
        minDelay: 259200,
        proposers: [governance.address],
        executors: [hre.ethers.constants.AddressZero],
        taxPercentageNumerator: 5,
        taxPercentageDenominator: 100,
        taxCooldown: 2.628e6,
    };
    const Timelock = await hre.ethers.getContractFactory("Timelock");
    const timelock = await Timelock.deploy(...Object.values(constructorArgsTimelock));
    config.timelockAddress = timelock.address;
    console.log("Deployed: Timelock");

    fs.writeFileSync("config.json", JSON.stringify(config));
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
