//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseLens} from "./BaseLens.sol";

contract UpdateTest is BaseLens {
    // Test that the lens can update the strategies
    function testUpdate() public {
        // Deposit an initial amount of tokens
        uint256 shares = _vault.deposit(_tokenAmount);

        // Update the strategy multiple times and check expected out
        for (uint256 i = 0; i < _strategy.length; i++) {
            _lens.update(_strategy[i]);

            uint256[] memory out = _vault.estimateRedeem(shares);
            for (uint256 i = 0; i < _token.length; i++) _assertApproxEq(expectedOut[i], out[i]);
        }

        _vault.redeem(shares);
    }
}
