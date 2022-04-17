//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Config {
    function getTokens() internal returns (IERC20[] memory tokens) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83); // wFTM
        tokens[1] = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75); // USDC
    }
}
