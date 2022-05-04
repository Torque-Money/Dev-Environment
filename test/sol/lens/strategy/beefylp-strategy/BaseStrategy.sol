//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {Base} from "../../../bases/Base.sol";
import {BaseUsesToken} from "../../../bases/BaseUsesToken.sol";

import {Config} from "../../../helpers/Config.sol";
import {BeefyLPStrategy} from "../../../../../src/lens/strategy/BeefyLPStrategy.sol";

abstract contract BaseStrategy is Base, BaseUsesToken {
    BeefyLPStrategy internal _strategy;

    IERC20Upgradeable[] internal _token;
    uint256[] internal _tokenAmount;

    function setUp() public virtual override {
        super.setUp();

        _token = Config.getToken();
        _tokenAmount = Config.getTokenAmount();

        _strategy = new BeefyLPStrategy();
        _strategy.initialize(_token, Config.getUniRouter(), Config.getUniFactory(), Config.getBeefyVault());

        _strategy.grantRole(_strategy.STRATEGY_CONTROLLER_ROLE(), address(this));

        address[] memory spender = new address[](1);
        spender[0] = address(_strategy);
        _approveAll(spender);
    }
}
