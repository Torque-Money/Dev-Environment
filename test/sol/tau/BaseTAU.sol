//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Base} from "../bases/Base.sol";

import {TorqueTAU} from "../../../src/tau/TorqueTAU.sol";

abstract contract BaseTAU is Base {
    TorqueTAU internal _tau;

    uint256 internal _initialSupply;
    uint256 internal _mintAmount;

    function setUp() public override {
        _initialSupply = Config.getTAUInitialSupply();
        _mintAmount = Config.getTAUMintAmount();

        _tau = new TorqueTAU();
        _tau.initialize(_initialSupply);
    }
}
