import deployPool from "./deployPool";
import deployOracle from "./deployOracle";
import deployConverter from "./deployConverter";
import deployMarginLong from "./deployMarginLong";
import deployToken from "./deployToken";
import deployGovernance from "./deployGovernance";
import deployReserve from "./deployReserve";

export default async function main() {
    // Deploy contracts
    await deployConverter();
    await deployPool();
    await deployOracle();
    await deployMarginLong();
    await deployToken();
    await deployGovernance();
    await deployReserve();
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
