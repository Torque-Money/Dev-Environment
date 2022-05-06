//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IWETH} from "../../../lib/weth/IWETH.sol";

import {IVaultWrapper} from "../../interfaces/lens/IVaultWrapper.sol";
import {IVault} from "../../interfaces/lens/IVault.sol";

contract VaultWrapper is Initializable, ContextUpgradeable, IVaultWrapper {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IWETH public weth;

    function initialize(IWETH _weth) external initializer {
        __Context_init();

        weth = _weth;
    }

    function deposit(IVault vault, uint256[] memory amount) external payable override returns (uint256 shares) {
        // Pull all tokens and convert ETH to its WETH equivalent and add it to the specified amount
        for (uint256 i = 0; i < vault.tokenCount(); i++) {
            IERC20Upgradeable token = vault.tokenByIndex(i);

            token.safeTransferFrom(_msgSender(), address(this), amount[i]);

            if (address(token) == address(weth)) {
                weth.deposit{value: msg.value}();
                amount[i] = amount[i].add(msg.value);
            }

            token.safeIncreaseAllowance(address(vault), amount[i]);
        }

        return vault.deposit(amount);
    }

    function redeem(IVault vault, uint256 shares) external override returns (uint256[] memory amount) {}

    receive() external payable {}
}
