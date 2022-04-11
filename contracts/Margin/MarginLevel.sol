//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {FractionMath} from "../lib/FractionMath.sol";

import {MarginAccount} from "./MarginAccount.sol";

abstract contract MarginLevel is Initializable, MarginAccount {
    using FractionMath for FractionMath.Fraction;

    FractionMath.Fraction private _maxLeverage;

    function initializeMarginLevel(uint256 maxLeverageNumerator_, uint256 maxLeverageDenominator_) public initializer {
        _maxLeverage.numerator = maxLeverageNumerator_;
        _maxLeverage.denominator = maxLeverageDenominator_;
    }

    // Set the maximum leverage
    function setMaxLeverage(uint256 maxLeverageNumerator_, uint256 maxLeverageDenominator_) external onlyRole(MARGIN_ADMIN) {
        _maxLeverage.numerator = maxLeverageNumerator_;
        _maxLeverage.denominator = maxLeverageDenominator_;
    }

    // Get the max leverage
    function maxLeverage() public view returns (uint256, uint256) {
        return _maxLeverage.export();
    }

    // Get the amount of leverage for a given account
    function currentLeverage(address account_) public view returns (uint256, uint256) {
        uint256 _initialBorrowPrice = initialBorrowPrice(account_);
        uint256 _accountPrice = accountPrice(account_);

        return (_initialBorrowPrice, _accountPrice);
    }

    // Get the minimum margin level before liquidation
    function minMarginLevel() public view returns (uint256, uint256) {
        return FractionMath.create(1, 1).add(FractionMath.create(1, 1).div(_maxLeverage)).export();
    }

    // Get the margin level of an account
    function marginLevel(address account_) public view returns (uint256, uint256) {
        (uint256 currentLeverageNumerator, uint256 currentLeverageDenominator) = currentLeverage(account_);

        return FractionMath.create(1, 1).add(FractionMath.create(currentLeverageDenominator, currentLeverageNumerator)).export();
    }

    // Check whether an account is liquidatable
    function liquidatable(address account_) public view returns (bool) {
        if (!_isBorrowing(account_)) return false;

        (uint256 marginLevelNumerator, uint256 marginLevelDenominator) = marginLevel(account_);
        FractionMath.Fraction memory _marginLevel = FractionMath.create(marginLevelNumerator, marginLevelDenominator);

        (uint256 minMarginLevelNumerator, uint256 minMarginLevelDenominator) = minMarginLevel();
        FractionMath.Fraction memory _minMarginLevel = FractionMath.create(minMarginLevelNumerator, minMarginLevelDenominator);

        return _marginLevel.lt(_minMarginLevel);
    }
}
