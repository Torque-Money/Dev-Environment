//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {BaseSupportsToken} from "./BaseSupportsToken.sol";

contract Token is BaseSupportsToken, BaseImpersonate {
    // Set the fee recipient
    function testSetFeeRecipient() public {}
}
