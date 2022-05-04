//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseSupportsToken} from "./BaseSupportsToken.sol";

contract Enumerate is BaseSupportsToken {
    // Test the token count
    function testTokenCount() public {
        assertEq(_token.length, _supportsToken.tokenCount());
    }

    // Test the enumeration of the tokens
    function testTokenEnumerate() public {
        for (uint256 i = 0; i < _token.length; i++) assertEq(address(_token[i]), address(_supportsToken.tokenByIndex(i)));
    }
}
