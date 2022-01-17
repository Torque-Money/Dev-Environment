import deployPool from "./deployPool";
import deployOracle from "./deployOracle";
import deployConverter from "./deployConverter";
import deployMarginLong from "./deployMarginLong";
import deployResolver from "./deployResolver";

export default async function main() {
    // Deploy contracts
    await deployConverter();
    await deployPool();
    await deployOracle();
    await deployMarginLong();
    await deployResolver();
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
