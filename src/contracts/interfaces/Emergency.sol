//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 *  Provides a contract with the option to eject its funds in the event that they get locked within
 */
interface Emergency {
    /**
     *  Allow a contract to eject tokens locked within
     */
    function inCaseTokensGetStuck(address token, uint256 amount) external;
}
