//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {LPoolProvide} from "./LPoolProvide.sol";
import {LPoolInterest} from "./LPoolInterest.sol";

contract LPool is Initializable, LPoolProvide, LPoolInterest {
    function initialize(
        address converter_,
        address oracle_,
        uint256 taxPercentNumerator_,
        uint256 taxPercentDenominator_,
        uint256 timePerInterestApplication_
    ) external initializer {
        initializeLPoolCore(converter_, oracle_);
        initializeLPoolTax(taxPercentNumerator_, taxPercentDenominator_);
        initializeLPoolInterest(timePerInterestApplication_);
    }
}
