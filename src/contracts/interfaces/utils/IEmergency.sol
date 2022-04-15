//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Allows a contract to eject its funds in the event that they get locked within.
interface IEmergency {
    // Allow a contract to eject tokens locked within.
    function inCaseTokensGetStuck(IERC20 token, uint256 amount) external;
}
