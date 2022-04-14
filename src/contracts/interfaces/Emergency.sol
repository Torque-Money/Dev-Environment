//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 *  Provides a contract with the option to eject its funds in the event that they get locked within
 */
interface Emergency {
    function inCaseTokensGetStuck(address token, uint256 amount) external;
}
