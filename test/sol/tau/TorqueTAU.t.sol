//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Base} from "../bases/Base.sol";

import {TorqueTAU} from "../../../src/tau/TorqueTAU.sol";

contract BaseTAU is Base {
    TorqueTAU internal _tau;

    uint256 internal _initialSupply;
    uint256 internal _mintAmount;

    function setUp() public override {
        _initialSupply = Config.getTAUInitialSupply();
        _mintAmount = Config.getTAUMintAmount();

        _tau = new TorqueTAU();
        _tau.initialize(_initialSupply);
    }

    // Check the initial supply minted
    function testInitialSupply() public {
        assertEq(tau.totalSupply(), initialSupply);
        assertEq(tau.balanceOf(address(this)), initialSupply);
    }

    // Fail to mint and burn tokens
    function testFailMint() public {
        tau.mint(address(this), mintAmount);
        tau.burn(address(this), mintAmount);
    }

    // Mint and burn tokens
    function testMintBurn() public {
        tau.grantRole(tau.TOKEN_MINTER_ROLE(), address(this));
        tau.grantRole(tau.TOKEN_BURNER_ROLE(), address(this));

        // **** Instead we should grant these roles to the deployer during the initializer

        tau.mint(address(this), mintAmount);
        tau.burn(address(this), mintAmount);

        tau.revokeRole(tau.TOKEN_BURNER_ROLE(), address(this));
        tau.revokeRole(tau.TOKEN_MINTER_ROLE(), address(this));
    }
}
