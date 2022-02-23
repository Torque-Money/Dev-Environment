import hre from "hardhat";
import {BigNumber} from "ethers";

import {shouldFail} from "../scripts/utils/helpers/utilTest";
import {wait} from "../scripts/utils/helpers/utilTest";
import {Timelock} from "../typechain-types";
import {chooseConfig, ConfigType} from "../scripts/utils/utilConfig";

describe("Timelock", async function () {
    const configType: ConfigType = "fork";
    const config = chooseConfig(configType);

    let timelock: Timelock;
    let minDelay: BigNumber;

    const executeAdminOnly = async ({address, value, calldata, description}: {address: string; value: number; calldata: string; description?: string}) => {
        const parsedPredecessor = hre.ethers.constants.HashZero;
        const parsedDescription = hre.ethers.utils.keccak256(ethers.utils.toUtf8Bytes(description || Date.now().toString()));

        await (await timelock.schedule(address, value, calldata, parsedPredecessor, parsedDescription, minDelay)).wait();

        const execute = async () => await (await timelock.execute(address, value, calldata, parsedPredecessor, parsedDescription)).wait();
        await shouldFail(execute);

        await wait(minDelay);

        await execute();
    };

    this.beforeAll(async () => {
        timelock = await hre.ethers.getContractAt("Timelock", config.contracts.timelockAddress);

        minDelay = await timelock.getMinDelay();
    });

    it("should execute an admin only request to the converter and attempt to upgrade it", async () => {
        const converter = await hre.ethers.getContractAt("Converter", config.contracts.converterAddress);
        await shouldFail(async () => await converter.setRouter(config.setup.routerAddress));

        await executeAdminOnly({
            address: converter.address,
            value: 0,
            calldata: converter.interface.encodeFunctionData("setRouter", [config.setup.routerAddress]),
        });
    });

    it("should execute an admin only request to the leveraging pool and attempt to upgrade it", async () => {
        const pool = await hre.ethers.getContractAt("LPool", config.contracts.leveragePoolAddress);
        await shouldFail(async () => await pool.setConverter(config.contracts.converterAddress));

        await executeAdminOnly({
            address: pool.address,
            value: 0,
            calldata: pool.interface.encodeFunctionData("setConverter", [config.contracts.converterAddress]),
        });
    });

    it("should execute an admin only request to the margin long and attempt to upgrade it", async () => {
        const marginLong = await hre.ethers.getContractAt("MarginLong", config.contracts.marginLongAddress);
        await shouldFail(async () => await marginLong.setOracle(config.contracts.oracleAddress));

        await executeAdminOnly({
            address: marginLong.address,
            value: 0,
            calldata: marginLong.interface.encodeFunctionData("setOracle", [config.contracts.oracleAddress]),
        });
    });

    it("should execute an admin only request to the oracle and attempt to upgrade it", async () => {
        const oracle = await hre.ethers.getContractAt("OracleTest", config.contracts.oracleAddress);
        const token = config.tokens.approved.filter((approved) => approved.oracle)[0];
        await shouldFail(async () => await oracle.setPriceFeed([token.address], [token.priceFeed], [token.decimals], [true]));

        await executeAdminOnly({
            address: oracle.address,
            value: 0,
            calldata: oracle.interface.encodeFunctionData("setPriceFeed", [[token.address], [token.priceFeed], [token.decimals], [true]]),
        });
    });

    // **** Test the token out too

    it("should execute an admin only request to the resolver and attempt to upgrade it", async () => {
        const resolver = await hre.ethers.getContractAt("Resolver", config.contracts.resolverAddress);
        await shouldFail(async () => await resolver.setConverter(config.contracts.converterAddress));

        await executeAdminOnly({
            address: resolver.address,
            value: 0,
            calldata: resolver.interface.encodeFunctionData("setConverter", [config.contracts.converterAddress]),
        });
    });

    it("should execute an admin only request to the flash lender and attempt to upgrade it", async () => {
        const flashLender = await hre.ethers.getContractAt("FlashLender", config.contracts.flashLender);
        await shouldFail(async () => await flashLender.setFeePercent(1, 1000000));

        await executeAdminOnly({
            address: flashLender.address,
            value: 0,
            calldata: flashLender.interface.encodeFunctionData("setFeePercent", [1, 1000000]),
        });
    });

    it("should attempt to upgrade the margin and pool and attempt to upgrade it", async () => {
        const proxyAdmin = await hre.upgrades.admin.getInstance();

        // **** Get implementation manually
        await shouldFail(async () => proxyAdmin.upgrade(config.contracts.leveragePoolAddress, config.contracts.leveragePoolLogicAddress));
        await executeAdminOnly({
            address: proxyAdmin.address,
            value: 0,
            calldata: proxyAdmin.interface.encodeFunctionData("upgrade", [config.leveragePoolAddress, config.leveragePoolLogicAddress]),
        });

        await shouldFail(async () => proxyAdmin.upgrade(config.marginLongAddress, config.marginLongLogicAddress));
        await executeAdminOnly({
            address: proxyAdmin.address,
            value: 0,
            calldata: proxyAdmin.interface.encodeFunctionData("upgrade", [config.marginLongAddress, config.marginLongLogicAddress]),
        });
    });
});
