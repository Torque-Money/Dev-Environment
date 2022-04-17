//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IVaultStrategyController} from "../../interfaces/lens/vault-strategy-controller/IVaultStrategyController.sol";
import {ChainlinkClient} from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Chainlink} from "@chainlink/contracts/src/v0.8/Chainlink.sol";

import {IVaultV1} from "../../interfaces/lens/vault/IVaultV1.sol";
import {IStrategy} from "../../interfaces/lens/strategy/IStrategy.sol";
import {Registry} from "../../utils/Registry.sol";
import {Emergency} from "../../utils/Emergency.sol";

contract VaultStrategyController is Initializable, AccessControlUpgradeable, IVaultStrategyController, Registry, Emergency, ChainlinkClient {
    using SafeMath for uint256;
    using Chainlink for Chainlink.Request;

    IVaultV1 private vault;

    bytes32 public CONTROLLER_ADMIN_ROLE;

    uint256 public nextUpdate;

    uint256 public APYRequestDelay;
    uint256 public APYUpdateDelay;

    bytes32 public CLSpecId;
    uint256 public CLPayment;

    string public apiURL;

    function initialize(
        uint256 _APYRequestDelay,
        uint256 _APYUpdateDelay,
        IVaultV1 _vault
    ) external initializer {
        __AccessControl_init();
        __Registry_init();
        __Emergency_init();

        CONTROLLER_ADMIN_ROLE = keccak256("CONTROLLER_ADMIN_ROLE");
        _setRoleAdmin(CONTROLLER_ADMIN_ROLE, CONTROLLER_ADMIN_ROLE);
        _grantRole(CONTROLLER_ADMIN_ROLE, _msgSender());

        vault = _vault;

        APYRequestDelay = _APYRequestDelay;
        APYUpdateDelay = _APYUpdateDelay;
    }

    function setCLToken(address link) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        setChainlinkToken(link);
    }

    function setCLOracle(address oracle) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        setChainlinkOracle(oracle);
    }

    function setCLSpecId(bytes32 specId) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        CLSpecId = specId;
    }

    function setCLPayment(uint256 payment) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        CLPayment = payment;
    }

    function setAPIUrl(string memory _apiURL) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        apiURL = _apiURL;
    }

    function getVault() external view returns (IVaultV1 _vault) {
        return vault;
    }

    function isUpdateable() public view override returns (bool updateable) {
        return block.timestamp >= nextUpdate;
    }

    function _updateStrategy() private {
        require(entryCount() > 0, "StrategyController: At least one strategy is required to update");

        // Find the highest APY strategy
        uint256 maxAPY;
        IStrategy strategy;
        for (uint256 i = 0; i < entryCount(); i++) {
            IStrategy _strategy = IStrategy(entryByIndex(i));
            (uint256 _apy, ) = _strategy.APY();

            if (_apy > maxAPY) {
                maxAPY = _apy;
                strategy = _strategy;
            }
        }

        // Update the vaults strategy
        if (strategy != vault.getStrategy()) {
            vault.withdrawAllFromStrategy();
            vault.setStrategy(strategy);
            vault.depositAllIntoStrategy();
        }
    }

    function _requestUpdateAPY() private {
        Chainlink.Request memory req = buildChainlinkRequest(CLSpecId, address(this), this.fulfillUpdate.selector);
        req.add("get", apiURL);
        sendOperatorRequest(req, CLPayment);

        nextUpdate = block.timestamp.add(APYRequestDelay);
    }

    function _updateAPY(string memory APYString) private {}

    function update() external override {
        require(isUpdateable(), "StrategyController: Not updateable");

        _requestUpdateAPY();
    }

    function fulfillUpdate(bytes32 requestId, bytes memory bytesData) external recordChainlinkFulfillment(requestId) {
        string memory APYString = string(bytesData);

        _updateAPY(APYString);
        _updateStrategy();
    }
}
