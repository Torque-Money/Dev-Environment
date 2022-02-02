import {expect} from "chai";
import {BigNumber} from "ethers";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/util/utilsTest";
import {ERC20, LPool, MarginLong, OracleTest, Resolver, Timelock} from "../typechain-types";

describe("Handle price movement", async function () {
    let collateralApproved: any;
    let collateralToken: ERC20;

    let borrowedApproved: any;
    let borrowedToken: ERC20;

    let resolver: Resolver;

    let signerAddress: string;

    let swapAmount: BigNumber;

    beforeEach(async () => {
        collateralApproved = config.approved[0];
        collateralToken = await ethers.getContractAt("ERC20", collateralApproved.address);

        borrowedApproved = config.approved[1];
        borrowedToken = await ethers.getContractAt("ERC20", borrowedApproved.address);

        resolver = await ethers.getContractAt("Resolver", config.resolverAddress);

        const swapAmount = ethers.BigNumber.from(10).pow(collateralApproved.decimals).mul(10);

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();
    });
});
