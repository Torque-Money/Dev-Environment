//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC3156FlashBorrowerUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC3156FlashLenderUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {LPool} from "../LPool/LPool.sol";

import {FlashLenderApproved} from "./FlashLenderApproved.sol";

abstract contract FlashLenderLend is ReentrancyGuardUpgradeable, FlashLenderApproved {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initializeFlashLenderLend() public initializer {
        __ReentrancyGuard_init();
    }

    // Get the maximum flash loan amount for a given token
    function maxFlashLoan(address token_) public view virtual onlyApproved(token_) returns (uint256) {
        return LPool(pool).liquidity(token_);
    }

    // Get the fee for borrowing a given amount of a given token
    function flashFee(address token_, uint256 amount_) public view virtual onlyApproved(token_) returns (uint256) {
        (uint256 feePercentNumerator, uint256 feePercentDenominator) = feePercent();
        return amount_.mul(feePercentNumerator).div(feePercentDenominator);
    }

    // Initiate flash loan
    function flashLoan(
        IERC3156FlashBorrowerUpgradeable receiver_,
        address token_,
        uint256 amount_,
        bytes memory data_
    ) public virtual whenNotPaused onlyApproved(token_) nonReentrant returns (bool) {
        require(amount_ > 0, "FlashLenderLend: Amount must be greater than 0");
        require(amount_ <= maxFlashLoan(token_), "FlashLenderLend: Amount exceeds max flash loan");

        uint256 fee = flashFee(token_, amount_);

        LPool(pool).withdraw(token_, amount_);
        IERC20Upgradeable(token_).safeTransfer(address(receiver_), amount_);

        require(receiver_.onFlashLoan(_msgSender(), token_, amount_, fee, data_) == CALLBACK_SUCCESS, "FlashLenderLend: Callback failed");

        uint256 finalBalance = IERC20Upgradeable(token_).balanceOf(address(this));
        require(finalBalance >= amount_.add(fee), "FlashLenderLend: Insufficient repay amount");
        IERC20Upgradeable(token_).safeTransfer(pool, finalBalance);

        return true;
    }
}
