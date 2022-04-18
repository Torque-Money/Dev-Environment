//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {UsesTokenBase} from "../../helpers/UsesTokenBase.sol";

import {Config} from "../../helpers/Config.sol";
import {Empty} from "../../helpers/Empty.sol";
import {MockStrategy} from "../../../mocks/MockStrategy.sol";
import {TorqueVaultV1} from "@contracts/lens/vault/TorqueVaultV1.sol";

contract VaultBase is DSTest, UsesTokenBase {
    ICheatCodes private cheats;
    address private empty;
    TorqueVaultV1 private vault;
    MockStrategy private strategy;

    function setUp() public virtual {
        empty = address(new Empty());

        cheats = Config.getCheatCodes();

        strategy = new MockStrategy();
        strategy.initialize(Config.getToken(), Config.getInitialAPY());

        vault = new TorqueVaultV1();
        vault.initialize(Config.getToken(), strategy, empty, 1, 1000);

        strategy.grantRole(strategy.STRATEGY_CONTROLLER_ROLE(), address(vault));
        vault.grantRole(vault.VAULT_CONTROLLER_ROLE(), address(this));

        address[] memory spender = new address[](1);
        spender[0] = address(vault);
        _approveAll(spender);
    }

    function _getEmpty() internal view returns (address _empty) {
        return empty;
    }

    function _getVault() internal view returns (TorqueVaultV1 _vault) {
        return vault;
    }

    function _getStrategy() internal view returns (MockStrategy _strategy) {
        return strategy;
    }

    function _getCheats() internal view returns (ICheatCodes _cheats) {
        return cheats;
    }
}
