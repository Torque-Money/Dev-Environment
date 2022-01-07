import deploy from "./deploy/deploy";
import setup from "./setup/setup";
import handover from "./handover/handover";

import utilFund from "./util/utilFund";
import utilApprove from "./util/utilApprove";

export default async function main() {
    await deploy();
    await setup();
    await handover();

    await utilFund();
    await utilApprove();
}

if (require.main === module)
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
