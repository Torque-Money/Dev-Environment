import handoverPool from "./handoverPool";
import handoverOracle from "./handoverOracle";
import handoverFlashswap from "./handoverFlashswap";
import handoverMarginLong from "./handoverMarginLong";
import handoverToken from "./handoverToken";
import handoverGovernance from "./handoverGovernance";
import handoverReserve from "./handoverReserve";

export default async function main() {
    // Handover the contracts
    await handoverPool();
    await handoverOracle();
    await handoverFlashswap();
    await handoverMarginLong();
    await handoverToken();
    await handoverGovernance();
    await handoverReserve();
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
