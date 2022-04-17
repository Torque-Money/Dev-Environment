//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Config} from "./Config.sol";

contract UsesTokenBase is DSTest {
    function setUp() public {
        Config.fundCaller();
    }

    function _getToken() internal pure returns (IERC20[] memory token) {
        return Config.getToken();
    }
}
