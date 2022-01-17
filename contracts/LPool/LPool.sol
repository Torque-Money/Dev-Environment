//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../Converter/IConverter.sol";
import "./LPoolStake.sol";
import "./LPoolInterest.sol";

contract LPool is LPoolStake, LPoolInterest {
    constructor(
        IConverter converter_,
        uint256 taxPercentNumerator_,
        uint256 taxPercentDenominator_,
        uint256 blocksPerCompound_
    ) LPoolTax(taxPercentNumerator_, taxPercentDenominator_) LPoolDeposit(converter_) LPoolInterest(blocksPerCompound_) {}
}
