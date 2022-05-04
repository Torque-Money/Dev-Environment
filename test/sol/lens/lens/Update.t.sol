//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseLens} from "./BaseLens.sol";

contract UpdateTest is BaseLens {
    // Test that the lens can update the strategies
    function testUpdate() public {
        uint256 shares = _vault.deposit(_tokenAmount);

        // **** Now in here in the

        uint256[] memory out = _vault.redeem(shares);
        for (uint256 i = 0; i < _token.length; i++) _assertApproxEq(expectedOut[i], out[i]);
    }
}
