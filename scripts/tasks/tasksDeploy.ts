import {task} from "hardhat/config";

import getConfigType from "../utils/config/utilConfigTypeSelector";

import deploy from "../deploy/deploy";
import setup from "../setup/setup";

export const taskDeploy = task("deploy", "Deploy contracts onto network", async (args, hre) => {
    await hre.run("compile");
    const configType = getConfigType(hre);

    await deploy(configType, hre);
    await setup(configType, hre);
});
