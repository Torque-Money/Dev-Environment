//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {OracleLP} from "./OracleLP.sol";

import {OracleCore} from "./OracleCore.sol";
import {IOracle} from "./IOracle.sol";

contract Oracle is Initializable, IOracle, OracleCore, OracleLP {
    function initialize(
        address pool_,
        uint256 priceDecimals_,
        uint256 thresholdNumerator_,
        uint256 thresholdDenominator_
    ) external initializer {
        initializeOracleCore(pool_, priceDecimals_, thresholdNumerator_, thresholdDenominator_);
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
