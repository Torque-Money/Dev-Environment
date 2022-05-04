//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Base} from "../bases/Base.sol";

import {TorqueTAU} from "../../../src/tau/TorqueTAU.sol";
import {Config} from "../helpers/Config.sol";

abstract contract BaseTAU is Base {
    TorqueTAU internal _tau;

    uint256 internal _initialSupply;
    uint256 internal _mintAmount;

    function setUp() public override {
        _initialSupply = Config.getTAUInitialSupply();
        _mintAmount = Config.getTAUMintAmount();

        _tau = new TorqueTAU();
        _tau.initialize(_initialSupply);

        _tau.grantRole(_tau.TOKEN_MINTER_ROLE(), address(this));
        _tau.grantRole(_tau.TOKEN_BURNER_ROLE(), address(this));
    }
}
