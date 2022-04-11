//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {FractionMath} from "../../../lib/FractionMath.sol";
import {Treasury} from "../Treasury.sol";
import {TreasurerCore} from "./TreasurerCore.sol";

abstract contract TreasurerDistributorCore is Initializable, TreasurerCore {
    using SafeMathUpgradeable for uint256;
    using FractionMath for FractionMath.Fraction;

    uint256 public rebaseCooldown;

    uint256 public resetTotalSupply;

    FractionMath.Fraction private _reserveTokenDistributionPercent;
    FractionMath.Fraction private _reserveTokenBackingDecayPercent;

    uint256 public maxHistoricalTreasuryValue;

    function initializeReserveDistributorCore(
        uint256 rebaseCooldown_,
        uint256 resetTotalSupply_,
        uint256 reserveTokenDistributionPercentNumerator_,
        uint256 reserveTokenDistributionPercentDenominator_,
        uint256 reserveTokenBackingDecayPercentNumerator_,
        uint256 reserveTokenBackingDecayPercentDenominator_
    ) public initializer {
        rebaseCooldown = rebaseCooldown_;

        resetTotalSupply = resetTotalSupply_;

        _reserveTokenDistributionPercent.numerator = reserveTokenDistributionPercentNumerator_;
        _reserveTokenDistributionPercent.denominator = reserveTokenDistributionPercentDenominator_;

        _reserveTokenBackingDecayPercent.numerator = reserveTokenBackingDecayPercentNumerator_;
        _reserveTokenBackingDecayPercent.denominator = reserveTokenBackingDecayPercentDenominator_;

        maxHistoricalTreasuryValue = 1;
    }

    // Set the rebase cooldown
    function setRebaseCooldown(uint256 rebaseCooldown_) external onlyOwner {
        rebaseCooldown = rebaseCooldown_;
    }

    // Set the total supply in the event of a reset
    function setResetTotalSupply(uint256 resetTotalSupply_) external onlyOwner {
        resetTotalSupply = resetTotalSupply_;
    }

    // Set the reserve token distribution percent
    function setReserveTokenDistributionPercent(uint256 reserveTokenDistributionPercentNumerator_, uint256 reserveTokenDistributionPercentDenominator_)
        external
        onlyOwner
    {
        _reserveTokenDistributionPercent.numerator = reserveTokenDistributionPercentNumerator_;
        _reserveTokenDistributionPercent.denominator = reserveTokenDistributionPercentDenominator_;
    }

    // Get the reserve distribution percent
    function reserveTokenDistributionPercent() public view returns (uint256, uint256) {
        return _reserveTokenDistributionPercent.export();
    }

    // Set the reserve token backing decay percent
    function setReserveTokenBackingDecayPercent(uint256 reserveTokenBackingDecayPercentNumerator_, uint256 reserveTokenBackingDecayPercentDenominator_)
        external
        onlyOwner
    {
        _reserveTokenBackingDecayPercent.numerator = reserveTokenBackingDecayPercentNumerator_;
        _reserveTokenBackingDecayPercent.denominator = reserveTokenBackingDecayPercentDenominator_;
    }

    // Get the reserve token backing decay percent
    function reserveTokenBackingDecayPercent() public view returns (uint256, uint256) {
        return _reserveTokenBackingDecayPercent.export();
    }

    // Set the max historical treasury value
    function _setMaxHistoricalTreasuryValue(uint256 value_) internal {
        maxHistoricalTreasuryValue = value_;
    }
}
