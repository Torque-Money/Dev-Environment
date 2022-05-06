//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IBeefyVaultV6} from "../../../../../lib/beefy/IBeefyVaultV6.sol";

import {Base} from "../../../bases/Base.sol";
import {BaseUsesToken} from "../../../bases/BaseUsesToken.sol";

import {Config} from "../../../helpers/Config.sol";
import {BeefyLPStrategy} from "../../../../../src/lens/strategy/BeefyLPStrategy.sol";

abstract contract BaseStrategy is Base, BaseUsesToken {
    BeefyLPStrategy internal _strategy;

    function setUp() public virtual override(Base, BaseUsesToken) {
        Base.setUp();
        BaseUsesToken.setUp();

        _strategy = new BeefyLPStrategy();
        (IUniswapV2Router02 router, IUniswapV2Factory factory, IBeefyVaultV6 beVault) = Config.getBeefyLPVaultParams();
        _strategy.initialize(_token, router, factory, beVault);

        _strategy.grantRole(_strategy.STRATEGY_CONTROLLER_ROLE(), address(this));

        address[] memory spender = new address[](1);
        spender[0] = address(_strategy);
        _approveAll(spender);
    }
}
