//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// Provides an interface for a contract to eject its funds in the event that they get locked within
interface IEmergency {
    // Allow a contract to eject tokens locked within. SHOULD be overriden for each smart contract to add authentication
    function inCaseTokensGetStuck(address token, uint256 amount) external;
}