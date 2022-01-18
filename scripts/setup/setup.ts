import setupPool from "./setupPool";
import setupOracle from "./setupOracle";
import setupMarginLong from "./setupMarginLong";

export default async function main(test: boolean = false) {
    // Setup the contracts
    await setupPool(test);
    await setupOracle(test);
    await setupMarginLong(test);
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
