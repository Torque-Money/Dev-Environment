//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC3156FlashBorrowerUpgradeable, IERC3156FlashLenderUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC3156FlashLenderUpgradeable.sol";

import {FlashLenderLend} from "./FlashLenderLend.sol";

contract FlashLender is Initializable, IERC3156FlashLenderUpgradeable, FlashLenderLend {
    function initialize(
        address pool_,
        uint256 feePercentNumerator_,
        uint256 feePercentDenominator_
    ) external initializer {
        initializeFlashLenderCore(pool_, feePercentNumerator_, feePercentDenominator_);
        initializeFlashLenderLend();
    }

    function maxFlashLoan(address token_) public view override(IERC3156FlashLenderUpgradeable, FlashLenderLend) returns (uint256) {
        return super.maxFlashLoan(token_);
    }

    function flashFee(address token_, uint256 amount_) public view override(IERC3156FlashLenderUpgradeable, FlashLenderLend) returns (uint256) {
        return super.flashFee(token_, amount_);
    }

    function flashLoan(
        IERC3156FlashBorrowerUpgradeable receiver_,
        address token_,
        uint256 amount_,
        bytes memory data_
    ) public override(IERC3156FlashLenderUpgradeable, FlashLenderLend) returns (bool) {
        return super.flashLoan(receiver_, token_, amount_, data_);
    }
}
