//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// Used for checking what tokens a contract supports and in what order.
interface ISupportsToken {
    // Returns if a token is supported by the contract.
    function isSupportedToken(IERC20Upgradeable token) external view returns (bool supportedToken);

    // Returns the number of tokens the contract supports.
    function tokenCount() external view returns (uint256 count);

    // Gets a token supported by the contract by its index.
    // Reverts if the index is not less than the token count.
    function tokenByIndex(uint256 index) external view returns (IERC20Upgradeable token);

    // Returns the amount of the given asset owned by the contract.
    // Not guaranteed to be the exact amount of tokens held by the contract - slight variation expected.
    // Reverts if the token is not supported.
    function approxBalance(IERC20Upgradeable token) external view returns (uint256 amount);

    // Returns the available amount of a given asset the contract can use.
    // By default returns the balance.
    // Not guranteed to be the exact amount of availabe tokens - slight variation expected.
    function approxAvailable(IERC20Upgradeable token) external view returns (uint256 amount);
}
