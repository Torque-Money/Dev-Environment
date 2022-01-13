import setupPool from "./setupPool";
import setupOracle from "./setupOracle";
import setupMarginLong from "./setupMarginLong";

export default async function main() {
    // Setup the contracts
    await setupPool();
    await setupOracle();
    await setupMarginLong();
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
