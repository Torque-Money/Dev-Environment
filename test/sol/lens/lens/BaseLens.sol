//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Base} from "../../bases/Base.sol";
import {BaseUsesToken} from "../../bases/BaseUsesToken.sol";

import {Config} from "../../helpers/Config.sol";
import {MockStrategy} from "../../../mocks/MockStrategy.sol";
import {Lens} from "../../../../src/lens/lens/Lens.sol";
import {Vault} from "../../../../src/lens/vault/Vault.sol";
import {BeefyLPStrategy} from "../../../../src/lens/strategy/BeefyLPStrategy.sol";
import {IStrategy} from "../../../../src/interfaces/lens/IStrategy.sol";

abstract contract BaseLens is Base, BaseUsesToken {
    IStrategy[] internal _strategy;

    Vault internal _vault;
    Lens internal _lens;

    function setUp() public virtual override(Base, BaseUsesToken) {
        Base.setUp();
        BaseUsesToken.setUp();

        _strategy = new IStrategy[](2);

        MockStrategy mock = new MockStrategy(_token);
        _strategy[0] = mock;

        BeefyLPStrategy beefy = new BeefyLPStrategy();
        beefy.initialize(_token, Config.getUniRouter(), Config.getUniFactory(), Config.getBeefyVault());
        _strategy[1] = beefy;

        _vault = new Vault();
        (uint256 feePercent, uint256 feeDenominator) = Config.getFee();
        _vault.initialize(_token, _strategy[0], address(this), feePercent, feeDenominator);

        _lens = new Lens();
        _lens.initialize(_vault);

        mock.grantRole(mock.STRATEGY_CONTROLLER_ROLE(), address(_vault));
        beefy.grantRole(beefy.STRATEGY_CONTROLLER_ROLE(), address(_vault));
        for (uint256 i = 0; i < _strategy.length; i++) _lens.add(address(_strategy[i]));

        _vault.grantRole(_vault.VAULT_CONTROLLER_ROLE(), address(_lens));
        _lens.grantRole(_lens.LENS_CONTROLLER_ROLE(), address(this));

        address[] memory spender = new address[](1);
        spender[0] = address(_vault);
        _approveAll(spender);
    }
}
