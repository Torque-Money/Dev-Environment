//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Chainlink, ChainlinkClient} from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

import {ILensController} from "../../interfaces/lens/ILensController.sol";

import {ILens} from "../../interfaces/lens/ILens.sol";

contract LensController is ChainlinkClient, AccessControl, ILensController {
    using Chainlink for Chainlink.Request;

    bytes32 public jobId;
    uint256 public fee;
    string public url;

    constructor(address link, address oracle, bytes32 _jobId, uint256 _fee, string memory _url) {
        setChainlinkToken(link);
        setChainlinkOracle(oracle);

        // **** SET UP SOME FORM OF ACCESS CONTROL IN HERE

        jobId = _jobId;
        fee = _fee;
        url = _url;
    }

    function setLinkToken(address link) external {
        setChainlinkToken(link);
    }

    function setOracle(address oracle) external {
        setChainlinkOracle(oracle);
    }

    function setJobId(bytes32 _jobId) external {
        jobId = _jobId;
    }

    function setFee(uint256 _fee) external {
        fee = _fee;
    }

    function setUrl(string memory _url) external {
        url = _url;
    }

    // **** We need some things to set the data up for the setters and getters as well

    // Get the lens that the controller controls.
    function getLens() external view override returns (ILens lens) {}

    // Returns whether or not the lens can update the strategy.
    function isUpdateable() external view override returns (bool _isUpdateable) {}

    // Update the strategy.
    function update() external override {}
}