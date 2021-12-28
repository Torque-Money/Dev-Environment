//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./LPoolStake.sol";
import "./LPoolInterest.sol";

contract LPool is LPoolStake, LPoolInterest {
    constructor(
        uint256 taxPercent_, uint256 maxInterestMin_,
        uint256 maxInterestMax_, uint256 maxUtilization_
    )
        LPoolTax(taxPercent_)
        LPoolInterest(maxInterestMin_, maxInterestMax_, maxUtilization_)
    {}
}