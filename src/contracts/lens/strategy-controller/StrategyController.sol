//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IStrategyController} from "../../interfaces/lens/strategy-controller/IStrategyController.sol";
import {ChainlinkClient} from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

import {Chainlink} from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import {IVaultV1} from "../../interfaces/lens/vault/IVaultV1.sol";
import {IStrategy} from "../../interfaces/lens/strategy/IStrategy.sol";
import {Registry} from "../../utils/Registry.sol";
import {Emergency} from "../../utils/Emergency.sol";

contract StrategyController is Initializable, AccessControlUpgradeable, IStrategyController, Registry, Emergency, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    IVaultV1 private vault;

    bytes32 public CONTROLLER_ADMIN_ROLE;

    uint256 private nextAPYUpdate;
    bool private _isStrategyUpdateable;

    function initialize(IVaultV1 _vault) external initializer {
        __AccessControl_init();
        __Registry_init();
        __Emergency_init();

        CONTROLLER_ADMIN_ROLE = keccak256("CONTROLLER_ADMIN_ROLE");
        _setRoleAdmin(CONTROLLER_ADMIN_ROLE, CONTROLLER_ADMIN_ROLE);
        _grantRole(CONTROLLER_ADMIN_ROLE, _msgSender());

        vault = _vault;
    }

    function setCLToken(address link) external {
        setChainlinkToken(link);
    }

    function setCLOracle(address oracle) external {
        setChainlinkOracle(oracle);
    }

    function isStrategyUpdateable() external view override returns (bool updateable) {
        return _isStrategyUpdateable;
    }

    function updateStrategy() external override onlyRole(CONTROLLER_ADMIN_ROLE) {
        // **** We are going to look through the strategies in the registry and get the one with the max APY, and then fix it all up
    }

    function isAPYUpdateable() external view override returns (bool updateable) {
        return block.timestamp >= nextAPYUpdate;
    }

    function updateAPY() external override onlyRole(CONTROLLER_ADMIN_ROLE) {
        // **** We are going to make a chainlink call, parse the data, and then update the strategy updateable
    }

    // **** I need to integrate this with chainlink requests
}
