//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// Allows a contract to eject its funds in the event that they get locked within.
interface IEmergency {
    // Allow a contract to eject tokens locked within.
    function inCaseTokensGetStuck(IERC20Upgradeable token, uint256 amount) external;
}
