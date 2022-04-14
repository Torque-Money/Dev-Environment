//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// import "@openzeppelin/con"
import {IEmergency} from "../interfaces/IEmergency.sol";

contract Emergency is IEmergency {
    function inCaseTokensGetStuck(address token, uint256 amount)
        external
        override
    {
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            // Handle ETH case
        } else {
            // Handle ERC20 case
        }
    }
}
