import setupPool from "./setupPool";
import setupOracle from "./setupOracle";
import setupIsolatedMargin from "./setupIsolatedMargin";
import setupYield from "./setupYield";

export default async function main() {
    // Setup the contracts
    await setupPool();
    await setupOracle();
    await setupIsolatedMargin();
    await setupYield();
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
