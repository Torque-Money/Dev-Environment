//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ISupportsToken} from "./utils/ISupportsToken.sol";

// A strategy that integrates with a vault to earn rewards on deposited tokens.
// Strategy should only ever integrate with a single vault.
interface IStrategy is ISupportsToken {
    // Deposit a given amount of funds from the caller into the strategy.
    // Reverts if sender does not have appropriate funds or has not allocated allowance.
    function deposit(uint256[] calldata amount) external;

    // Deposit all of the callers funds into the strategy.
    // Reverts if sender has not approved funds.
    function depositAll() external;

    // Withdraw a given amount of the contracts funds to the caller.
    // Returns the amount of tokens the caller receives.
    // Reverts if there are not enough funds available in the contract.
    // Not guaranteed to withdraw the exact amount specified.
    function withdraw(uint256[] calldata amount) external returns (uint256[] calldata actual);

    // Withdraw all of the contracts funds to the caller.
    // Returns the amount of tokens the caller receives.
    function withdrawAll() external returns (uint256[] calldata actual);
}
