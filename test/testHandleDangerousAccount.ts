import {expect} from "chai";
import {ethers} from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/util/utilsTest";
import {ERC20, LPool, MarginLong, Resolver} from "../typechain-types";

describe("Liquidate", async function () {
    let marginLong: MarginLong;
    let pool: LPool;
    let resolver: Resolver;
    let collateralToken: ERC20;
    let borrowedToken: ERC20;
    let lpToken: ERC20;
    let signerAddress: string;

    beforeEach(async () => {
        pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);
        resolver = await ethers.getContractAt("Resolver", config.resolverAddress);

        collateralToken = await ethers.getContractAt("ERC20", config.approved[0].address);
        borrowedToken = await ethers.getContractAt("ERC20", config.approved[1].address);
        lpToken = await ethers.getContractAt("ERC20", await pool.LPFromPT(borrowedToken.address));

        const signer = ethers.provider.getSigner();
        signerAddress = await signer.getAddress();

        // **** Now here we want to deposit collateral and such into the account and see what happens and if it is liquidatable
    });

    it("should liquidate a dangerous account", async () => {});

    it("should reset a dangerous account", async () => {});
});
