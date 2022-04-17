//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";

import {UsesTokenBase} from "../../helpers/UsesTokenBase.sol";

import {Config} from "../../helpers/Config.sol";
import {Empty} from "../../helpers/Empty.sol";
import {MockStrategy} from "../../../mocks/MockStrategy.sol";
import {TorqueVaultV1} from "@contracts/lens/vault/TorqueVaultV1.sol";

contract VaultBase is DSTest, UsesTokenBase {
    Empty private empty;
    TorqueVaultV1 private vault;
    MockStrategy private strategy;

    function setUp() public {
        empty = new Empty();

        strategy = new MockStrategy();
        strategy.initialize(Config.getToken(), Config.getInitialAPY());

        vault = new TorqueVaultV1();
        vault.initialize(Config.getToken(), strategy, address(empty), 1, 1000);

        strategy.grantRole(strategy.STRATEGY_CONTROLLER_ROLE(), address(vault));
        vault.grantRole(vault.VAULT_CONTROLLER_ROLE(), address(this));

        _fundCaller();

        address[] memory toApprove = new address[](2);
        toApprove[0] = address(strategy);
        toApprove[1] = address(vault);
        _approveAll(toApprove);
    }

    function _getEmpty() internal view returns (Empty _empty) {
        return empty;
    }

    function _getVault() internal view returns (TorqueVaultV1 _vault) {
        return vault;
    }

    function _getStrategy() internal view returns (MockStrategy _strategy) {
        return strategy;
    }
}
