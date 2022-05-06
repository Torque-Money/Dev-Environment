import { getUpgradeableBeaconFactory } from "@openzeppelin/hardhat-upgrades/dist/utils";
import hre from "hardhat";

import { loadData } from "../../utils";

async function main() {
    const data = loadData();

    const beaconAddress = data.contracts["LensV1.0"].beacon;
    const newOwner = data.contracts.timelock;

    const beacon = (await getUpgradeableBeaconFactory(hre, hre.ethers.provider.getSigner())).attach(beaconAddress);

    await (await beacon.transferOwnership(newOwner)).wait();
    console.log("Setup | Beacon | Ownership transferred");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
