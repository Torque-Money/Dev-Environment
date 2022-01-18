import deploy from "./deploy/deploy";
import setup from "./setup/setup";

import utilFund from "./util/utilFund";
import utilApprove from "./util/utilApprove";
import utilUpdateFiles from "./util/utilUpdateFiles";

// **** I need to add some sort of option for command line argument parsing
// **** I might remove the boolean = false by default later

export default async function main(test: boolean = false) {
    await deploy();
    await setup();

    await utilFund();
    await utilApprove();
    await utilUpdateFiles();
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
