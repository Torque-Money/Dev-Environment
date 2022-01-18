import setupPool from "./setupPool";
import setupOracle from "./setupOracle";
import setupMarginLong from "./setupMarginLong";

export default async function main(test: boolean) {
    await setupPool(test);
    await setupOracle(test);
    await setupMarginLong(test);
}
