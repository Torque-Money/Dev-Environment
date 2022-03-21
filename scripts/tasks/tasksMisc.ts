import {task} from "hardhat/config";

import {verifyAll} from "../utils/utilVerify";

export default function main() {
    task("verify-all", "Verify all contracts on block explorer", async (args, hre) => await verifyAll(hre));
}
