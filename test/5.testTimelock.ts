import {BigNumber} from "ethers";
import {ethers, network, upgrades} from "hardhat";
import proxyConfig from "../.openzeppelin/unknown-31337.json";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/util/utilsTest";
import {Timelock} from "../typechain-types";

describe("Timelock", async function () {
    let timelock: Timelock;
    let minDelay: BigNumber;

    const waitTime = async (seconds: BigNumber) => {
        await network.provider.send("evm_increaseTime", [seconds.toNumber()]);
        await network.provider.send("evm_mine");
    };

    const executeAdminOnly = async ({address, value, calldata, description}: {address: string; value: number; calldata: string; description?: string}) => {
        const parsedPredecessor = ethers.constants.HashZero;
        const parsedDescription = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(description || ""));

        await timelock.schedule(address, value, calldata, parsedPredecessor, parsedDescription, minDelay);

        const execute = async () => await timelock.execute(address, value, calldata, parsedPredecessor, parsedDescription);
        await shouldFail(execute);

        await waitTime(minDelay);

        await execute();
    };

    beforeEach(async () => {
        timelock = await ethers.getContractAt("Timelock", config.timelockAddress);

        minDelay = await timelock.getMinDelay();
    });

    it("should execute an admin only request to the converter", async () => {
        const converter = await ethers.getContractAt("Converter", config.converterAddress);
        await shouldFail(async () => await converter.setRouter(config.routerAddress));

        await executeAdminOnly({
            address: converter.address,
            value: 0,
            calldata: converter.interface.encodeFunctionData("setRouter", [config.routerAddress]),
        });
    });

    it("should execute an admin only request to the leveraging pool", async () => {
        const pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
        await shouldFail(async () => await pool.setConverter(config.converterAddress));

        await executeAdminOnly({
            address: pool.address,
            value: 0,
            calldata: pool.interface.encodeFunctionData("setConverter", [config.converterAddress]),
        });
    });

    it("should execute an admin only request to the margin long", async () => {
        const marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);
        await shouldFail(async () => await marginLong.setOracle(config.oracleAddress));

        await executeAdminOnly({
            address: marginLong.address,
            value: 0,
            calldata: marginLong.interface.encodeFunctionData("setOracle", [config.oracleAddress]),
        });
    });

    it("should execute an admin only request to the oracle", async () => {
        const oracle = await ethers.getContractAt("OracleTest", config.oracleAddress);
        const token = config.approved[0];
        await shouldFail(async () => await oracle.setPriceFeed([token.address], [token.priceFeed], [token.reservePriceFeed], [token.decimals], [true]));

        await executeAdminOnly({
            address: oracle.address,
            value: 0,
            calldata: oracle.interface.encodeFunctionData("setPriceFeed", [[token.address], [token.priceFeed], [token.reservePriceFeed], [token.decimals], [true]]),
        });
    });

    it("should execute an admin only request to the resolver", async () => {
        const resolver = await ethers.getContractAt("Resolver", config.resolverAddress);
        await shouldFail(async () => await resolver.setConverter(config.converterAddress));

        await executeAdminOnly({
            address: resolver.address,
            value: 0,
            calldata: resolver.interface.encodeFunctionData("setConverter", [config.converterAddress]),
        });
    });

    it("should attempt to upgrade the margin and pool", async () => {
        // **** Do this using the admin proxy to upgrade the contract

        // **** PANIC STATIONS - THOSE IMPLEMENTATIONS OF POOL AND MARGIN ARE NOT CORRECT ADDRESSES

        const proxyAdmin = await upgrades.admin.getInstance();
        await shouldFail(async () => proxyAdmin.upgrade());
    });
});
