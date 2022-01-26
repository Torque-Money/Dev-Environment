//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Converter/IConverter.sol";
import "../Oracle/IOracle.sol";
import "./LPoolProvide.sol";
import "./LPoolInterest.sol";

contract LPool is Initializable, LPoolProvide, LPoolInterest {
    function initialize(
        IConverter converter_,
        IOracle oracle_,
        uint256 taxPercentNumerator_,
        uint256 taxPercentDenominator_,
        uint256 blocksPerInterestApplication_
    ) external initializer {
        LPoolCore.initialize(converter_, oracle_);
        LPoolTax.initialize(taxPercentNumerator_, taxPercentDenominator_);
        LPoolInterest.initialize(blocksPerInterestApplication_);
    }
}
