import {expect} from "chai";
import {BigNumber} from "ethers";
import {network} from "hardhat";
import {ConfigType} from "../utilConfig";

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

export async function approxEqual(a: BigNumber, b: BigNumber, percentError: number) {
    const DISCRIMINATOR = 10 ** percentError;

    try {
        expect(a.sub(b).abs().mul(DISCRIMINATOR).lt(b)).to.equal(true);
    } catch (e) {
        console.log(`a: ${a.toString()} | b: ${b.toString()} | percent error: ${percentError}`);
        throw e;
    }
}

export const CONFIG_TYPE: ConfigType = "main";

export const BIG_NUM = BigNumber.from(2).pow(96);

export const COLLATERAL_PRICE = BigNumber.from(1);
export const BORROW_PRICE = BigNumber.from(100);
