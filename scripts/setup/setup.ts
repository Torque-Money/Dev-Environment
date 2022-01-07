import setupPool from "./setupPool";
import setupOracle from "./setupOracle";
import setupMarginLong from "./setupMarginLong";
import setupReserve from "./setupReserve";

export default async function main() {
    // Setup the contracts
    await setupPool();
    await setupOracle();
    await setupMarginLong();
    await setupReserve();
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
