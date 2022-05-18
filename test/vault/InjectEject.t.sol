//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {BaseVault} from "./BaseVault.sol";

import {Config} from "../helpers/Config.sol";

contract InjectEjectTest is BaseVault {
    // Test the flow of funds between the vault and the strategy
    function testFundFlow() public useFunds(vm) {
        // Make deposit
        uint256 shares = _vault.deposit(_tokenAmount);

        // Check that vault has been allocated the correct amount of tokens and they have flowed into the right contracts (Maybe move this to a seperate test ???)
        for (uint256 i = 0; i < _token.length; i++) {
            assertEq(_vault.approxBalance(_token[i]), _tokenAmount[i]);
            assertEq(_token[i].balanceOf(address(_vault)), 0);

            assertEq(_strategy.approxBalance(_token[i]), _tokenAmount[i]);
            assertEq(_token[i].balanceOf(address(_strategy)), _tokenAmount[i]);
        }

        _vault.redeem(shares);
    }
}
