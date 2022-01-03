import setupPool from "./setupPool";
import setupOracle from "./setupOracle";
import setupFlashswap from "./setupFlashswap";
import setupIsolatedMargin from "./setupIsolatedMargin";
import setupToken from "./setupToken";
import setupTimelock from "./setupTimelock";
import setupYield from "./setupYield";

export default async function main() {
    // Setup the contracts
    await setupPool();
    await setupOracle();
    await setupFlashswap();
    await setupIsolatedMargin();
    await setupToken();
    await setupTimelock();
    await setupYield();
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
