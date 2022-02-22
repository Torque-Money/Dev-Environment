import {expect} from "chai";
import {BigNumber} from "ethers";
import {network} from "hardhat";

export async function shouldFail(fn: () => Promise<any>) {
    try {
        await fn();
        expect(true).to.equal(false);
    } catch {}
}

export async function wait(seconds: BigNumber) {
    await network.provider.send("evm_increaseTime", [seconds.toNumber()]);
    await network.provider.send("evm_mine");
}

export async function approxEqual(a: BigNumber, b: BigNumber, decimals: number) {
    const DISCRIMINATOR = 10 ** decimals;
    expect(a.sub(b).abs().lt(DISCRIMINATOR)).to.equal(true);
}
