import {expect} from "chai";
import {BigNumber} from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {ConfigType} from "../utilConfig";

import utilFund from "../../utils/utilFund";
import utilApprove from "../../utils/utilApprove";
import utilClump from "../../utils/utilClump";

export async function shouldFail(fn: () => Promise<any>) {
    try {
        await fn();
        expect(true).to.equal(false);
    } catch {}
}

export async function wait(hre: HardhatRuntimeEnvironment, seconds: BigNumber) {
    await hre.network.provider.send("evm_increaseTime", [seconds.toNumber()]);
    await hre.network.provider.send("evm_mine");
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

export async function testWrapper(hre: HardhatRuntimeEnvironment, callback: () => Promise<any>) {
    await utilFund(CONFIG_TYPE, hre);
    await utilApprove(CONFIG_TYPE, hre);

    await callback();

    await utilClump(CONFIG_TYPE, hre);
}

export const CONFIG_TYPE: ConfigType = "fork";

export const BIG_NUM = BigNumber.from(2).pow(96);

export const COLLATERAL_PRICE = BigNumber.from(1);
export const BORROW_PRICE = BigNumber.from(100);
