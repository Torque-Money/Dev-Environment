//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/lens/vault/ITorqueVaultV1.sol";
import "../../interfaces/lens/strategy/IStrategy.sol";

contract USDCFTMVault is Initializable, ITorqueVaultV1, ERC20Upgradeable {
    function setStrategy(IStrategy strategy) external override {}

    function tokenCount() external view override returns (uint256 count) {}

    function tokenByIndex(uint256 index) external view override returns (IERC20 token) {}

    function previewDeposit(uint256[] calldata amount) external view override returns (uint256 shares) {}

    function deposit(uint256[] calldata amount) external override returns (uint256 shares) {}

    function previewRedeem(uint256 shares) external view override returns (uint256[] memory amount) {}

    function redeem(uint256 shares) external override returns (uint256[] memory amount) {}

    function balance(IERC20 token) external override returns (uint256 amount) {}
}