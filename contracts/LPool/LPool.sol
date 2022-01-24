//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../Converter/IConverter.sol";
import "../Oracle/IOracle.sol";
import "./LPoolProvide.sol";
import "./LPoolInterest.sol";

contract LPool is LPoolProvide, LPoolInterest {
    constructor(
        IConverter converter_,
        IOracle oracle_,
        uint256 taxPercentNumerator_,
        uint256 taxPercentDenominator_,
        uint256 blocksPerInterestApplication_
    ) LPoolCore(converter_, oracle_) LPoolTax(taxPercentNumerator_, taxPercentDenominator_) LPoolInterest(blocksPerInterestApplication_) {}
}
