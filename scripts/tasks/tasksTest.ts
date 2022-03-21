import {task} from "hardhat/config";

import {testWrapper} from "../utils/utilTest";

export default function main() {
    task("test-functionality", "Run functionality tests", async (args, hre) => {
        const basePath = process.cwd() + "/test/functionality/";

        const files = ["1.functionTimelock.ts", "2.functionInterest.ts", "3.functionHandlePriceMovement.ts", "4.functionalFlashLend.ts"].map((file) => basePath + file);

        await testWrapper(hre, async () => await hre.run("test", {testFiles: files}));
    });

    task("test-usability", "Run usability tests", async (args, hre) => {
        const basePath = process.cwd() + "/test/usability/";

        const files = ["1.usabilityPool.ts", "2.usabilityOracle.ts", "3.usabilityConverter.ts", "4.usabilityMarginLong.ts"].map((file) => basePath + file);

        await testWrapper(hre, async () => await hre.run("test", {testFiles: files}));
    });

    task("test-verify-deployed", "Run verification of deployed contracts tests", async (args, hre) => {
        const basePath = process.cwd() + "/test/verifyDeployed/";

        const files = [
            "1.verifyPool.ts",
            "2.verifyOracle.ts",
            "3.verifyTimelock.ts",
            "4.verifyConverter.ts",
            "5.verifyFlashLend.ts",
            "6.verifyResolver.ts",
            "7.verifyMarginLong.ts",
        ].map((file) => basePath + file);

        await hre.run("test", {testFiles: files});
    });
}
