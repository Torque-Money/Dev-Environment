//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ISupportsToken} from "../../utils/ISupportsToken.sol";

// A strategy that integrates with a vault to earn rewards on deposited tokens.
interface IStrategy is ISupportsToken {
    // Deposit a given amount of funds into the strategy.
    // Reverts if sender does not have appropriate funds or has not allocated allowance.
    function deposit(uint256[] calldata amount) external;

    // Withdraw a given amount of funds from the strategy.
    // Reverts if there are not enough funds available in the contract.
    function withdraw(uint256[] calldata amount) external;

    // Get the current APY and decimals for the strategy.
    function APY() external view returns (uint256 apy, uint256 decimals);

    // Update the current APY for the strategy.
    // Specifies the decimals used in the input APY.
    // Calling APY does not necessarily mean it will be the new value submitted here.
    function updateAPY(uint256 apy, uint256 decimals) external;
}
