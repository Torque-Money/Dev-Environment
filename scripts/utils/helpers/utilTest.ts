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

export function approxEqual(a: BigNumber, b: BigNumber, percentError: number) {
    const DISCRIMINATOR = 10 ** percentError;

    expect(a.sub(b).abs().mul(DISCRIMINATOR).lt(b)).to.equal(true);
}

// **** Replace all comparisons with this one and check if it fixes the issue
export function addressEqual(address1: string, address2: string) {
    expect(address1.toLowerCase()).to.equal(address2);
}

export async function testWrapper(hre: HardhatRuntimeEnvironment, callback: () => Promise<any>) {
    const configType = await getConfigType(hre);

    await utilFund(configType, hre);
    await utilApprove(configType, hre);

    await callback();

    await utilClump(configType, hre);
}
