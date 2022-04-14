//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IEmergency} from "../interfaces/utils/IEmergency.sol";

contract Emergency is IEmergency {
    using SafeERC20 for IERC20;

    function inCaseTokensGetStuck(IERC20 token, uint256 amount)
        external
        override
    {
        if (address(token) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            payable(msg.sender).transfer(amount);
        else token.safeTransfer(msg.sender, amount);
    }
}
