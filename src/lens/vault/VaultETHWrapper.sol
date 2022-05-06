//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {TransferHelper} from "../../../lib/transfer-helper/TransferHelper.sol";
import {IWETH} from "../../../lib/weth/IWETH.sol";

import {IVaultETHWrapper} from "../../interfaces/lens/IVaultETHWrapper.sol";
import {IVault} from "../../interfaces/lens/IVault.sol";

contract VaultETHWrapper is Initializable, ContextUpgradeable, IVaultETHWrapper {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IVault;

    IWETH public weth;

    function initialize(IWETH _weth) external initializer {
        __Context_init();

        weth = _weth;
    }

    function deposit(IVault vault, uint256[] memory amount) external payable override returns (uint256 shares) {
        // Pull all tokens and convert ETH to its WETH equivalent and add it to the specified amount
        for (uint256 i = 0; i < vault.tokenCount(); i++) {
            IERC20Upgradeable token = vault.tokenByIndex(i);

            if (address(token) == address(weth)) {
                weth.deposit{value: msg.value}();
                amount[i] = msg.value;
            } else token.safeTransferFrom(_msgSender(), address(this), amount[i]);

            token.safeIncreaseAllowance(address(vault), amount[i]);
        }

        shares = vault.deposit(amount);
        vault.safeTransfer(_msgSender(), shares);
    }

    function redeem(IVault vault, uint256 shares) external override returns (uint256[] memory amount) {
        vault.safeTransferFrom(_msgSender(), address(this), shares);
        amount = vault.redeem(shares);

        for (uint256 i = 0; i < vault.tokenCount(); i++) {
            IERC20Upgradeable token = vault.tokenByIndex(i);

            if (address(token) == address(weth)) {
                weth.withdraw(amount[i]);
                TransferHelper.safeTransferETH(_msgSender(), amount[i]);
            } else token.safeTransfer(_msgSender(), amount[i]);
        }
    }

    receive() external payable {}
}
