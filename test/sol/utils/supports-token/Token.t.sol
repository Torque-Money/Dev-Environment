//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {BaseSupportsToken} from "./BaseSupportsToken.sol";

contract Token is BaseSupportsToken, BaseImpersonate {
    // Test the token count
    function testTokenCount() public {
        assertEq(_token.length, _supportsToken.tokenCount());
    }

    // Test the enumeration of the tokens
    function testTokenEnumerate() public {
        for (uint256 i = 0; i < _token.length; i++) assertEq(_token[i], _supportsFee.tokenByIndex(i));
    }
}
