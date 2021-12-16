import hre from "hardhat";

async function main() {
    // Manipulate the time of the chain
    const args = process.argv.slice(2);
    console.log(args);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
