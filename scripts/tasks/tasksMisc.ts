import {task} from "hardhat/config";

import {verifyAll} from "../utils/utilVerify";

export const taskVerifyAll = task("verify-all", "Verify all contracts on block explorer", async (args, hre) => await verifyAll(hre));
