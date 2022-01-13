import deploy from "./deploy/deploy";
import setup from "./setup/setup";

import utilFund from "./util/utilFund";
import utilApprove from "./util/utilApprove";
import utilUpdateFiles from "./util/utilUpdateFiles";

export default async function main() {
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
