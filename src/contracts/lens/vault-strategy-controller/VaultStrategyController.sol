//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IVaultStrategyController} from "../../interfaces/lens/vault-strategy-controller/IVaultStrategyController.sol";
import {ChainlinkClient} from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

import {Chainlink} from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import {IVaultV1} from "../../interfaces/lens/vault/IVaultV1.sol";
import {IStrategy} from "../../interfaces/lens/strategy/IStrategy.sol";
import {Registry} from "../../utils/Registry.sol";
import {Emergency} from "../../utils/Emergency.sol";

contract VaultStrategyController is Initializable, AccessControlUpgradeable, IVaultStrategyController, Registry, Emergency, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    IVaultV1 private vault;

    bytes32 public CONTROLLER_ADMIN_ROLE;

    uint256 public nextAPYUpdate;
    bool public strategyUpdateable;

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

    function isStrategyUpdateable() public view override returns (bool updateable) {
        return strategyUpdateable;
    }

    function updateStrategy() external override {
        require(isStrategyUpdateable(), "StrategyController: Strategy is not updateable");
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

        strategyUpdateable = false;

        emit UpdateStrategy(_msgSender());
    }

    function isAPYUpdateable() public view override returns (bool updateable) {
        return block.timestamp >= nextAPYUpdate;
    }

    function updateAPY() external override {
        require(isAPYUpdateable(), "StrategyController: APY is not updateable");

        Chainlink.Request memory req = buildChainlinkRequest(CLSpecId, address(this), this.fulfillUpdateAPY.selector);
    }

    function fulfillUpdateAPY(bytes32 requestId, bytes memory bytesData) external recordChainlinkFulfillment(requestId) {
        // **** So now we are going to take the requested bytes and parse the new APY's from this and update each strategy accordingly
        // **** We are also going to update the request possibility
    }

    // **** I need to integrate this with chainlink requests - request will need to integrate event too
}
