//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC3156FlashBorrowerUpgradeable, IERC3156FlashLenderUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC3156FlashLenderUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract FlashBorrowerTest is Initializable, IERC3156FlashBorrowerUpgradeable, ContextUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize() external initializer {
        __Context_init();
    }

    // Call the flash loan
    function callFlashLoan(
        address token_,
        uint256 amount_,
        address lender_
    ) external {
        IERC3156FlashLenderUpgradeable(lender_).flashLoan(IERC3156FlashBorrowerUpgradeable(address(this)), token_, amount_, "");
    }

    // Flash loan receiver
    function onFlashLoan(
        address,
        address token_,
        uint256,
        uint256,
        bytes memory
    ) public returns (bytes32) {
        IERC20Upgradeable(token_).safeTransfer(_msgSender(), IERC20Upgradeable(token_).balanceOf(address(this)));
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
