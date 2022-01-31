import {BigNumber} from "ethers";
import {network} from "hardhat";

export default async function wait(seconds: BigNumber) {
    await network.provider.send("evm_increaseTime", [seconds.toNumber()]);
    await network.provider.send("evm_mine");
}
