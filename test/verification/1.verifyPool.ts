import hre from "hardhat";

import {chooseConfig} from "../../scripts/utils/utilConfig";
import getConfigType from "../../scripts/utils/utilConfigTypeSelector";

describe("Pool", async function () {
    const configType = await getConfigType(hre);
    const config = chooseConfig(configType);

    this.beforeAll(async () => {});

    this.beforeEach(async () => {});

    this.afterEach(async () => {});

    this.afterAll(async () => {});

    it("", async () => {});
});
