import {BigNumber} from "ethers";
import {ethers, network} from "hardhat";
import config from "../config.fork.json";
import {shouldFail} from "../scripts/util/utilsTest";
import {Timelock} from "../typechain-types";

// **** I need a seperate function to delay the time to make the timelock instant
// **** Dont forget to revoke the admin role from the timelock (or dont initially)

// **** I need the timelock to control the proxy upgrade address also ****

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

    // it("should execute an admin only request to the leveraging pool", async () => {
    //     const pool = await ethers.getContractAt("LPool", config.leveragePoolAddress);
    //     await shouldFail(async () => await pool.setConverter(config.converterAddress));

    //     await executeAdminOnly({
    //         address: pool.address,
    //         value: 0,
    //         calldata: pool.interface.encodeFunctionData("setConverter", [config.converterAddress]),
    //     });
    // });

    // it("should execute an admin only request to the margin long", async () => {
    //     const marginLong = await ethers.getContractAt("MarginLong", config.marginLongAddress);
    //     await shouldFail(async () => await marginLong.setOracle(config.oracleAddress));

    //     await executeAdminOnly({
    //         address: marginLong.address,
    //         value: 0,
    //         calldata: marginLong.interface.encodeFunctionData("setOracle", [config.oracleAddress]),
    //     });
    // });

    // it("should execute an admin only request to the oracle", async () => {
    //     const oracle = await ethers.getContractAt("OracleTest", config.oracleAddress);
    //     const token = config.approved[0];
    //     await shouldFail(async () => await oracle.setPriceFeed([token.address], [token.priceFeed], [token.reservePriceFeed], [token.decimals], [true]));

    //     await executeAdminOnly({
    //         address: oracle.address,
    //         value: 0,
    //         calldata: oracle.interface.encodeFunctionData("setPriceFeed", [[token.address], [token.priceFeed], [token.reservePriceFeed], [token.decimals], [true]]),
    //     });
    // });
});

// describe("DAO", async () => {
//     it("Should create a proposal, vote on the proposal, then execute the proposal after the given time", async () => {
//         // Initialize the contracts
//         const signer = ethers.provider.getSigner();
//         const signerAddress = await signer.getAddress();
//         const dao = new ethers.Contract(config.governanceAddress, DAO.abi, signer);
//         const timelock = new ethers.Contract(config.timelockAddress, Timelock.abi, signer);
//         const testToken = new ethers.Contract(config.approved[0].address, ERC20.abi, signer);
//         const token = new ethers.Contract(config.tokenAddress, ERC20Votes.abi, signer);

//         // ======== Transfer tokens to the timelock ========
//         const initialBal = await testToken.balanceOf(signerAddress);
//         const tokenAmount = (1e18).toString();
//         await testToken.transfer(timelock.address, tokenAmount);
//         console.log("Transferred tokens to the timelock");

//         // ======== Create a proposal to transfer tokens back to owner ========
//         const transferCallData = testToken.interface.encodeFunctionData("transfer", [signerAddress, tokenAmount]);
//         const proposalConfig = {
//             contracts: [testToken.address],
//             values: [0],
//             calldata: [transferCallData],
//             description: `Proposal #${Date.now()}: Give grant to owner`,
//         };
//         await dao["propose(address[],uint256[],bytes[],string)"](...Object.values(proposalConfig));
//         proposalConfig.description = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(proposalConfig.description));
//         const proposalId = await dao["hashProposal(address[],uint256[],bytes[],bytes32)"](...Object.values(proposalConfig));

//         console.log(`Proposed grant for owner with proposal id: ${proposalId.toHexString()}`);

//         // ======== Vote on proposal ========
//         const voterBalance = await token.balanceOf(signerAddress);
//         console.log(`Token balance of voter: ${voterBalance}`);

//         const stateInitial = await dao.state(proposalId);
//         console.log(`Initial state of proposal: ${stateInitial}`);

//         await token.delegate(signerAddress);
//         const signerVotes = await token.getVotes(signerAddress);
//         console.log(`Signer has ${signerVotes} votes`);

//         await dao.castVote(proposalId, 1);
//         const hasVoted = await dao.hasVoted(proposalId, signerAddress);
//         console.log(`Voted status: ${hasVoted}`);

//         skipBlocks(5);

//         const stateAfter = await dao.state(proposalId);
//         console.log(`Final state of proposal: ${stateAfter}`);

//         // ======== Queue the proposal for the timelock **** move time forward for this ========

//         await dao["queue(address[],uint256[],bytes[],bytes32)"](...Object.values(proposalConfig));
//         console.log("Queued proposal for execution");

//         await timeTravel(1);

//         // Execute the proposal and check that the balance is the same
//         await dao["execute(address[],uint256[],bytes[],bytes32)"](...Object.values(proposalConfig));
//         expect(await testToken.balanceOf(signerAddress)).to.equal(initialBal);

//         // **** Eventually integrate the yield and other tokens into this for a full test AND add the correct ownerships and such
//     });
// });
