//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {BaseEmergency} from "./BaseEmergency.sol";

import {Config} from "../../helpers/Config.sol";

contract Withdraw is EmergencyBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Test that an ERC20 token is withdrawable
    function testERC20Withdraw() public useFunds(vm) {
        IERC20Upgradeable[] memory token = Config.getToken();

        for (uint256 i = 0; i < token.length; i++) {
            uint256 balance = token[i].balanceOf(address(this));

            token[i].safeTransfer(address(emergency), balance);
            emergency.inCaseTokensGetStuck(token[i], balance);

            assertEq(token[i].balanceOf(address(this)), balance);
        }
    }
}
