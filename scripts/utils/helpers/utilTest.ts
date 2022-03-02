import {expect} from "chai";
import {BigNumber} from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import utilFund from "../../utils/utilFund";
import utilApprove from "../../utils/utilApprove";
import utilClump from "../../utils/utilClump";
import getConfigType from "../utilConfigTypeSelector";

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
    const configType = await getConfigType(hre);

    await utilFund(configType, hre);
    await utilApprove(configType, hre);

    await callback();

    await utilClump(configType, hre);
}

export const BIG_NUM = BigNumber.from(2).pow(96);

export const COLLATERAL_PRICE = BigNumber.from(1);
export const BORROW_PRICE = BigNumber.from(100);
