import handoverPool from "./handoverPool";
import handoverOracle from "./handoverOracle";
import handoverFlashswap from "./handoverFlashswap";
import handoverIsolatedMargin from "./handoverIsolatedMargin";
import handoverToken from "./handoverToken";
import handoverTimelock from "./handoverTimelock";

export default async function main() {
    // Handover the contracts
    await handoverPool();
    await handoverOracle();
    await handoverFlashswap();
    await handoverIsolatedMargin();
    await handoverToken();
    await handoverTimelock();
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
