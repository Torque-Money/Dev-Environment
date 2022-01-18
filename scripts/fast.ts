import deploy from "./deploy/deploy";
import setup from "./setup/setup";

import utilFund from "./util/utilFund";
import utilApprove from "./util/utilApprove";
import utilUpdateFiles from "./util/utilUpdateFiles";

export default async function main(test: boolean) {
    await deploy(test);
    await setup(test);

    await utilFund(test);
    await utilApprove(test);
    await utilUpdateFiles();
}

if (require.main === module) {
    let test = false;

    const argv = process.argv.slice(2);

    main(test)
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}
