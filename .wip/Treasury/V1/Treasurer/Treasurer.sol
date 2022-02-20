//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {TreasurerStake} from "./TreasurerStake.sol";

contract Treasurer is Initializable, TreasurerStake {
    function initialize(
        address oracle_,
        address treasury_,
        address reserveToken_,
        address wrappedReserveToken_,
        uint256 minStakeTime_,
        uint256 rebaseCooldown_,
        uint256 resetTotalSupply_,
        uint256 reserveTokenDistributionPercentNumerator_,
        uint256 reserveTokenDistributionPercentDenominator_,
        uint256 reserveTokenBackingDecayPercentNumerator_,
        uint256 reserveTokenBackingDecayPercentDenominator_
    ) external initializer {
        initializeReserveCore(oracle_, treasury_, reserveToken_, wrappedReserveToken_);
        initializeReserveWrapped(minStakeTime_);
        initializeReserveDistributorCore(
            rebaseCooldown_,
            resetTotalSupply_,
            reserveTokenDistributionPercentNumerator_,
            reserveTokenDistributionPercentDenominator_,
            reserveTokenBackingDecayPercentNumerator_,
            reserveTokenBackingDecayPercentDenominator_
        );
    }
}
