//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// A strategy that integrates with a vault to earn rewards on deposited tokens.
interface IStrategy {
    // Deposit a given amount of funds into the strategy.
    // Reverts if caller does not have appropriate funds or has not allocated allowance.
    function deposit(uint256[] calldata amount) external;

    // Withdraw a given amount of funds from the strategy.
    // Reverts if there are not enough funds available in the contract.
    function withdraw(uint256[] calldata amount) external;

    // Get the balance of funds available to be withdrawn from the strategy.
    function balance(IERC20 token) external view returns (uint256 amount);

    event Deposit(address indexed caller, uint256[] amount);
    event Withdraw(address indexed caller, uint256[] amount);
}