//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IStrategy} from "./IStrategy.sol";

// Strategy that has an APY.
interface IStrategyAPY is IStrategy {
    // Get the current APY and decimals for the strategy.
    function APY() external view returns (uint256 apy, uint256 decimals);

    // Update the current APY for the strategy.
    // Calling APY after does not necessarily need to equal the submitted APY.
    function updateAPY(uint256 apy) external;
}
