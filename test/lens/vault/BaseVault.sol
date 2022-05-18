//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Base} from "../../bases/Base.sol";
import {BaseUsesToken} from "../../bases/BaseUsesToken.sol";

import {Config} from "../../helpers/Config.sol";
import {MockStrategy} from "../../mocks/MockStrategy.sol";
import {Vault} from "../../../src/lens/vault/Vault.sol";

abstract contract BaseVault is Base, BaseUsesToken {
    Vault internal _vault;
    MockStrategy internal _strategy;

    uint256 internal _feePercent;
    uint256 internal _feeDenominator;

    function setUp() public virtual override(Base, BaseUsesToken) {
        Base.setUp();
        BaseUsesToken.setUp();

        (_feePercent, _feeDenominator) = Config.getFee();

        _strategy = new MockStrategy(_token);

        _vault = new Vault();
        _vault.initialize(_token, _strategy, _empty, _feePercent, _feeDenominator);

        _strategy.grantRole(_strategy.STRATEGY_CONTROLLER_ROLE(), address(_vault));
        _vault.grantRole(_vault.VAULT_CONTROLLER_ROLE(), address(this));

        address[] memory spender = new address[](1);
        spender[0] = address(_vault);
        _approveAll(spender);
    }
}
