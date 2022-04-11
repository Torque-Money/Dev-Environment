//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {FractionMath} from "../lib/FractionMath.sol";

abstract contract FlashLenderCore is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    using FractionMath for FractionMath.Fraction;

    bytes32 public FLASHLENDER_ADMIN;

    address public pool;

    FractionMath.Fraction private _feePercent;

    bytes32 public CALLBACK_SUCCESS;

    function initializeFlashLenderCore(
        address pool_,
        uint256 feePercentNumerator_,
        uint256 feePercentDenominator_
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();

        FLASHLENDER_ADMIN = keccak256("FLASHLENDER_ADMIN_ROLE");
        _setRoleAdmin(FLASHLENDER_ADMIN, FLASHLENDER_ADMIN);
        _grantRole(FLASHLENDER_ADMIN, _msgSender());

        pool = pool_;

        _feePercent.numerator = feePercentNumerator_;
        _feePercent.denominator = feePercentDenominator_;

        CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    // Pause the contract
    function pause() external onlyRole(FLASHLENDER_ADMIN) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(FLASHLENDER_ADMIN) {
        _unpause();
    }

    // Set the pool to use
    function setPool(address pool_) external onlyRole(FLASHLENDER_ADMIN) {
        pool = pool_;
    }

    // Set the fee percentage
    function setFeePercent(uint256 feePercentNumerator_, uint256 feePercentDenominator_) external onlyRole(FLASHLENDER_ADMIN) {
        _feePercent.numerator = feePercentNumerator_;
        _feePercent.denominator = feePercentDenominator_;
    }

    // Get the fee percent
    function feePercent() public view returns (uint256, uint256) {
        return _feePercent.export();
    }
}
