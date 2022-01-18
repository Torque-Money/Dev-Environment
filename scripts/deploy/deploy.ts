import deployPool from "./deployPool";
import deployOracle from "./deployOracle";
import deployConverter from "./deployConverter";
import deployMarginLong from "./deployMarginLong";
import deployResolver from "./deployResolver";

export default async function main(test: boolean = false) {
    // Deploy contracts
    await deployConverter(test);
    await deployPool(test);
    await deployOracle(test);
    await deployMarginLong(test);
    await deployResolver(test);
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
