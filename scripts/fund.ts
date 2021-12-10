import hre from "hardhat";
import config from "../config.json";
import ERC20Abi from "@openzeppelin/contracts/build/contracts/ERC20.json";

async function main() {
    // Compile contracts
    await hre.run("compile");

    // Account to fund with tokens
    const signer = hre.ethers.provider.getSigner();

    // Fund the account with DAI
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [config.daiWhale],
    });
    const daiSigner = await hre.ethers.getSigner(config.daiWhale);
    const dai = new hre.ethers.Contract(config.daiAddress, ERC20Abi.abi, daiSigner);

    const daiBalance = await dai.balanceOf(daiSigner.address);
    await dai.transfer(signer._address, daiBalance);

    console.log(`Transferred ${daiBalance.toString()} DAI to signer ${signer._address}`);

    // Fund the account with BOO
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [config.booWhale],
    });
    const booSigner = await hre.ethers.getSigner(config.booWhale);
    const boo = new hre.ethers.Contract(config.booAddress, ERC20Abi.abi, booSigner);

    const booBalance = await boo.balanceOf(booSigner.address);
    await boo.transfer(signer._address, booBalance);

    console.log(`Transferred ${booBalance.toString()} BOO to signer ${signer._address}`);

    // Approve the contracts to spend DAI and BOO
    const signerDai = dai.connect(signer);
    await signerDai.approve(config.poolAddress, daiBalance);
    await signerDai.approve(config.marginAddress, daiBalance);
    console.log(`Approved contracts to spend DAI`);

    const signerBoo = boo.connect(signer);
    await signerBoo.approve(config.poolAddress, booBalance);
    await signerBoo.approve(config.marginAddress, booBalance);
    console.log(`Approved contracts to spend BOO`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
