//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {OracleLP} from "./OracleLP.sol";

import {OracleCore} from "./OracleCore.sol";
import {IOracle} from "./IOracle.sol";

contract OracleTest is Initializable, PausableUpgradeable, IOracle, OracleCore, OracleLP {
    using SafeMathUpgradeable for uint256;

    function initialize(
        address pool_,
        uint256 priceDecimals_,
        uint256 thresholdNumerator_,
        uint256 thresholdDenominator_
    ) external initializer {
        __Pausable_init();

        initializeOracleCore(pool_, priceDecimals_, thresholdNumerator_, thresholdDenominator_);
    }

    mapping(address => uint256) private _customPrices;

    // Pause the contract
    function pause() external onlyRole(ORACLE_ADMIN) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(ORACLE_ADMIN) {
        _unpause();
    }

    // Custom price
    function _price(address token_, uint256 amount_) internal view override returns (uint256) {
        if (_customPrices[token_] > 0) return _customPrices[token_].mul(amount_).div(10**decimals(token_));
        else return super._price(token_, amount_);
    }

    // Set the price for a particular token
    function setPrice(address token_, uint256 price_) external whenNotPaused {
        _customPrices[token_] = price_;
    }

    function isSupported(address token_) public view override(IOracle, OracleLP) returns (bool) {
        return super.isSupported(token_);
    }

    function priceDecimals() public view override(IOracle, OracleCore) returns (uint256) {
        return super.priceDecimals();
    }

    function priceMin(address token_, uint256 amount_) public view override(IOracle, OracleLP) returns (uint256) {
        return super.priceMin(token_, amount_);
    }

    function priceMax(address token_, uint256 amount_) public view override(IOracle, OracleLP) returns (uint256) {
        return super.priceMax(token_, amount_);
    }

    function amountMin(address token_, uint256 price_) public view override(IOracle, OracleLP) returns (uint256) {
        return super.amountMin(token_, price_);
    }

    function amountMax(address token_, uint256 price_) public view override(IOracle, OracleLP) returns (uint256) {
        return super.amountMax(token_, price_);
    }
}
