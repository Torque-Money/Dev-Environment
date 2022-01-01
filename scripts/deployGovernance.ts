import hre, { ethers } from "hardhat";
import fs from "fs";
import { getContractAddress } from "ethers/lib/utils";
import config from "../config.json";

export default async function main() {
    const constructorArgs1 = {
        initialSupply: ethers.BigNumber.from(1000000000).mul(10).pow(18),
    };
    const Token = await hre.ethers.getContractFactory("Token");
    const token = await Token.deploy(...Object.values(constructorArgs1));
    // @ts-ignore
    config.tokenAddress = token.address;
    console.log("Deployed: Governance token");

    const signer = hre.ethers.provider.getSigner();
    const transactionCount = await signer.getTransactionCount();
    const timelockAddress = getContractAddress({
        from: await signer.getAddress(),
        nonce: transactionCount + 1,
    });

    const constructorArgs2 = {
        token: token.address,
        timelockAddress: timelockAddress,
        quorumFraction: 6,
        votingDelay: hre.ethers.BigNumber.from(86400).div(config.avgBlockTime),
        votingPeriod: hre.ethers.BigNumber.from(604800).div(config.avgBlockTime),
        proposalThreshold: 2,
    };
    const Governor = await hre.ethers.getContractFactory("Governor");
    const governor = await Governor.deploy(...Object.values(constructorArgs2));
    // @ts-ignore
    config.governorAddress = governor.address;
    console.log("Deployed: Governor");

    const constructorArgs3 = {
        minDelay: 259200,
        proposers: [governor.address],
        executors: [hre.ethers.constants.AddressZero],
        taxPercentageNumerator: 5,
        taxPercentageDenominator: 100,
        taxCooldown: 2.628e6,
    };
    const Timelock = await hre.ethers.getContractFactory("Timelock");
    const timelock = await Timelock.deploy(...Object.values(constructorArgs3));
    // @ts-ignore
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
