import deploy from "./deploy/deploy";
import setup from "./setup/setup";

import utilFund from "./util/utilFund";
import utilApprove from "./util/utilApprove";
import utilUpdateFiles from "./util/utilUpdateFiles";
import {HardhatRuntimeEnvironment} from "hardhat/types";

const TEST = false;

export default async function main(test: boolean, hre: HardhatRuntimeEnvironment) {
    await deploy(test, hre);
    await setup(test, hre);

    await utilFund(test, hre);
    await utilApprove(test, hre);
    await utilUpdateFiles();
}
