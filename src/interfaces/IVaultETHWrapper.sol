//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IWETH} from "../../lib/weth/IWETH.sol";

import {IVault} from "./IVault.sol";

// Wraps around a vault and allows for ETH to ERC20 deposits by autowrapping.
interface IVaultETHWrapper {
    // Get the wrapped ETH token 'WETH' that the vault wrapper users.
    function WETH() external view returns (IWETH weth);

    // Deposits senders funds into the vault and exchanges any ETH for its wrapped equivalent.
    // Sender will receive the same number of shares as if they had deposited themselves.
    function deposit(IVault vault, uint256[] calldata amount) external payable returns (uint256 shares);

    // Redeems senders shares and exchanges their wrapped ETH equivalent for ETH.
    // Sender will receive their amounts as if they had redeemed the shares themselves.
    function redeem(IVault vault, uint256 shares) external returns (uint256[] calldata amount);
}
