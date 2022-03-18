import {expect} from "chai";
import {BigNumber} from "ethers";
import {HardhatRuntimeEnvironment} from "hardhat/types";

import utilFund from "./utilFund";
import utilApprove from "./utilApprove";
import utilClump from "./utilClump";
import getConfigType from "../config/utilConfigTypeSelector";

// Throw an exception if the function doesnt throw an exception
export async function shouldFail(fn: () => Promise<any>) {
    try {
        await fn();
        expect(true).to.equal(false);
    } catch {}
}

// Set the blockchains time to the given number of seconds in the future
export async function wait(hre: HardhatRuntimeEnvironment, seconds: BigNumber) {
    await hre.network.provider.send("evm_increaseTime", [seconds.toNumber()]);
    await hre.network.provider.send("evm_mine");
}

// Throw an exception if the elements are not approximately equal
export function approxEqual(a: BigNumber, b: BigNumber, percentError: number) {
    const DISCRIMINATOR = 10 ** percentError;

    expect(a.sub(b).abs().mul(DISCRIMINATOR).lt(b)).to.equal(true);
}

// Check if two addresses are equal
export function expectAddressEqual(address1: string, address2: string) {
    expect(address1.toLowerCase()).to.equal(address2.toLowerCase());
}

// Include all necessary options for testing
export async function testWrapper(hre: HardhatRuntimeEnvironment, callback: () => Promise<any>) {
    const configType = getConfigType(hre);

    await utilFund(configType, hre);
    await utilApprove(configType, hre);

    await callback();

    await utilClump(configType, hre);
}
