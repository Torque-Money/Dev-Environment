//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {FractionMath} from "../lib/FractionMath.sol";

abstract contract OracleCore is Initializable, AccessControlUpgradeable {
    using FractionMath for FractionMath.Fraction;

    bytes32 public ORACLE_ADMIN;

    address public pool;
    uint256 private _priceDecimals;

    FractionMath.Fraction private _threshold;

    function initializeOracleCore(
        address pool_,
        uint256 priceDecimals_,
        uint256 thresholdNumerator_,
        uint256 thresholdDenominator_
    ) public initializer {
        __AccessControl_init();

        ORACLE_ADMIN = keccak256("ORACLE_ADMIN_ROLE");
        _setRoleAdmin(ORACLE_ADMIN, ORACLE_ADMIN);
        _grantRole(ORACLE_ADMIN, _msgSender());

        pool = pool_;
        _priceDecimals = priceDecimals_;

        _threshold.numerator = thresholdNumerator_;
        _threshold.denominator = thresholdDenominator_;
    }

    // Set the pool to use
    function setPool(address pool_) external onlyRole(ORACLE_ADMIN) {
        pool = pool_;
    }

    // Set the price decimals
    function setPriceDecimals(uint256 priceDecimals_) external onlyRole(ORACLE_ADMIN) {
        _priceDecimals = priceDecimals_;
    }

    // Get the price decimals
    function priceDecimals() public view virtual returns (uint256) {
        return _priceDecimals;
    }

    // Set the threshold
    function setThreshold(uint256 thresholdNumerator_, uint256 thresholdDenominator_) external onlyRole(ORACLE_ADMIN) {
        _threshold.numerator = thresholdNumerator_;
        _threshold.denominator = thresholdDenominator_;
    }

    // Get the threshold
    function threshold() public view returns (uint256, uint256) {
        return _threshold.export();
    }
}
