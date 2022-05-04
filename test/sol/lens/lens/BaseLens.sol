//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Base} from "../../bases/Base.sol";
import {BaseUsesToken} from "../../bases/BaseUsesToken.sol";

import {Config} from "../../helpers/Config.sol";
import {MockStrategy} from "../../../mocks/MockStrategy.sol";
import {Lens} from "../../../../src/lens/lens/Lens.sol";
import {Vault} from "../../../../src/lens/vault/Vault.sol";

abstract contract BaseLens is Base, BaseUsesToken {
    MockStrategy[] internal _strategy;
    Vault internal _vault;
    Lens internal _lens;

    function setUp() public virtual override(Base, BaseUsesToken) {
        Base.setUp();
        BaseUsesToken.setUp();

        _strategy = new MockStrategy[](2);
        _strategy[0] = new MockStrategy(_token);
        _strategy[1] = new MockStrategy(_token);

        _vault = new Vault();
        (uint256 feePercent, uint256 feeDenominator) = Config.getFee();
        _vault.initialize(_token, _strategy[0], address(this), feePercent, feeDenominator);

        _lens = new Lens();
        _lens.initialize(_vault);

        _strategy.grantRole(_strategy.STRATEGY_CONTROLLER_ROLE(), address(this));
    }
}
