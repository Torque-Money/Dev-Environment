//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {Base} from "../../helpers/Base.sol";
import {UsesTokenBase} from "../../helpers/UsesTokenBase.sol";

import {Config} from "../../helpers/Config.sol";
import {MockStrategy} from "../../../mocks/MockStrategy.sol";
import {TorqueVaultV1} from "../../../../src/lens/vault/TorqueVaultV1.sol";

contract VaultBase is Base, UsesTokenBase {
    TorqueVaultV1 private vault;
    MockStrategy private strategy;

    function setUp() public virtual override {
        super.setUp();

        strategy = new MockStrategy();
        strategy.initialize(Config.getToken());

        vault = new TorqueVaultV1();
        vault.initialize(Config.getToken(), strategy, _getEmpty(), 1, 1000);

        strategy.grantRole(strategy.STRATEGY_CONTROLLER_ROLE(), address(vault));
        vault.grantRole(vault.VAULT_CONTROLLER_ROLE(), address(this));

        address[] memory spender = new address[](1);
        spender[0] = address(vault);
        _approveAll(spender);
    }

    function _getVault() internal view returns (TorqueVaultV1 _vault) {
        return vault;
    }

    function _getStrategy() internal view returns (MockStrategy _strategy) {
        return strategy;
    }

    function _getCheats() internal view virtual override(Base, UsesTokenBase) returns (ICheatCodes _cheats) {
        return super._getCheats();
    }
}
