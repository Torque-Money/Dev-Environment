//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Chainlink, ChainlinkClient} from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {ILensController} from "../../interfaces/lens/ILensController.sol";

import {ILens} from "../../interfaces/lens/ILens.sol";
import {IStrategy} from "../../interfaces/lens/IStrategy.sol";

contract LensController is ChainlinkClient, AccessControl, ILensController {
    using Chainlink for Chainlink.Request;
    using SafeMath for uint256;

    bytes32 public LENS_CONTROLLER_ADMIN_ROLE = keccak256("LENS_CONTROLLER_ADMIN_ROLE");

    ILens private _lens;

    uint256 public updateableAt;
    uint256 public updateCooldown;
    uint256 public requestUpdateCooldown;

    bytes32 public jobId;
    uint256 public fee;
    string public url;
    string public jsonPath;

    constructor(
        ILens lens,
        uint256 _updateCooldown,
        uint256 _requestUpdateCooldown,
        address link,
        address oracle,
        bytes32 _jobId,
        uint256 _fee,
        string memory _url,
        string memory _jsonPath
    ) {
        setChainlinkToken(link);
        setChainlinkOracle(oracle);

        _setRoleAdmin(LENS_CONTROLLER_ADMIN_ROLE, LENS_CONTROLLER_ADMIN_ROLE);
        _grantRole(LENS_CONTROLLER_ADMIN_ROLE, _msgSender());

        _lens = lens;

        updateCooldown = _updateCooldown;
        requestUpdateCooldown = _requestUpdateCooldown;

        jobId = _jobId;
        fee = _fee;
        url = _url;
        jsonPath = _jsonPath;
    }

    function setLens(ILens lens) external onlyRole(LENS_CONTROLLER_ADMIN_ROLE) {
        _lens = lens;
    }

    function getLens() external view override returns (ILens lens) {
        return _lens;
    }

    function setUpdateCooldown(uint256 _updateCooldown) external onlyRole(LENS_CONTROLLER_ADMIN_ROLE) {
        updateCooldown = _updateCooldown;
    }

    function setRequestUpdateCooldown(uint256 _requestUpdateCooldown) external onlyRole(LENS_CONTROLLER_ADMIN_ROLE) {
        requestUpdateCooldown = _requestUpdateCooldown;
    }

    function setLinkToken(address link) external onlyRole(LENS_CONTROLLER_ADMIN_ROLE) {
        setChainlinkToken(link);
    }

    function setOracle(address oracle) external onlyRole(LENS_CONTROLLER_ADMIN_ROLE) {
        setChainlinkOracle(oracle);
    }

    function setJobId(bytes32 _jobId) external onlyRole(LENS_CONTROLLER_ADMIN_ROLE) {
        jobId = _jobId;
    }

    function setFee(uint256 _fee) external onlyRole(LENS_CONTROLLER_ADMIN_ROLE) {
        fee = _fee;
    }

    function setUrl(string memory _url) external onlyRole(LENS_CONTROLLER_ADMIN_ROLE) {
        url = _url;
    }

    function setJsonPath(string memory _jsonPath) external onlyRole(LENS_CONTROLLER_ADMIN_ROLE) {
        jsonPath = _jsonPath;
    }

    function isUpdateable() public view override returns (bool _isUpdateable) {
        return block.timestamp > updateableAt;
    }

    function update() external override {
        require(isUpdateable(), "LensController: Update is not available");

        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("get", url);
        req.add("path", jsonPath);

        sendChainlinkRequest(req, fee);

        updateableAt = block.timestamp.add(requestUpdateCooldown);
    }

    function fulfill(bytes32 requestId, uint256 index) external recordChainlinkFulfillment(requestId) {
        IStrategy newStrategy = IStrategy(_lens.entryByIndex(index));

        if (address(_lens.getVault().getStrategy()) != address(newStrategy)) _lens.update(newStrategy);

        updateableAt = block.timestamp.add(updateCooldown);
    }
}
