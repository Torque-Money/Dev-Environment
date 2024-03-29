//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseLens} from "./BaseLens.sol";

import {IStrategy} from "../../src/interfaces/IStrategy.sol";

contract UpdateTest is BaseLens {
    // Test that the lens can update the strategies
    function testUpdate() public useFunds(vm) {
        // Deposit an initial amount of tokens
        uint256 shares = _vault.deposit(_tokenAmount);

        // Update the strategy multiple times and check expected out
        for (uint256 i = 0; i < _strategy.length; i++) {
            if (_strategy[i] != _vault.getStrategy()) {
                _lens.update(_strategy[i]);

                uint256[] memory out = _vault.estimateRedeem(shares);
                for (uint256 j = 0; j < _token.length; j++) _assertApproxEq(_tokenAmount[i], out[i]);
            }
        }

        _vault.redeem(shares);
    }

    // Test that only a registered strategy may be used
    function testFailUpdateUnregistered() public {
        _lens.update(IStrategy(address(0)));
    }

    // Test that the current strategy cannot be used
    function testFailUpdateCurrent() public {
        _lens.update(_vault.getStrategy());
    }
}
