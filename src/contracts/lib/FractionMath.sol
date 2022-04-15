//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library FractionMath {
    using FractionMath for Fraction;
    using SafeMath for uint256;

    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }

    modifier onlyValid(Fraction memory fraction) {
        require(isValid(fraction), "FractionMath: Denominator of fraction cannot equal 0");
        _;
    }

    function isValid(Fraction memory fraction) internal pure returns (bool) {
        return fraction.denominator != 0;
    }

    function create(uint256 a, uint256 b) internal pure returns (Fraction memory fraction) {
        fraction = Fraction({numerator: a, denominator: b});
        require(isValid(fraction), "FractionMath: Denominator of fraction cannot equal 0");
    }

    function export(Fraction memory fraction) internal pure onlyValid(fraction) returns (uint256, uint256) {
        return (fraction.numerator, fraction.denominator);
    }

    function add(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (Fraction memory fraction) {
        fraction.numerator = a.numerator.mul(b.denominator).add(b.numerator.mul(a.denominator));
        fraction.denominator = a.denominator.mul(b.denominator);
    }

    function sub(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (Fraction memory fraction) {
        fraction.numerator = a.numerator.mul(b.denominator).sub(b.numerator.mul(a.denominator));
        fraction.denominator = a.denominator.mul(b.denominator);
    }

    function mul(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (Fraction memory fraction) {
        fraction.numerator = a.numerator.mul(b.numerator);
        fraction.denominator = a.denominator.mul(b.denominator);
    }

    function div(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (Fraction memory fraction) {
        require(b.numerator != 0, "FractionMath: Divisior fraction cannot equal 0");
        fraction.numerator = a.numerator.mul(b.denominator);
        fraction.denominator = a.denominator.mul(b.numerator);
    }

    function eq(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) == b.numerator.mul(a.denominator);
    }

    function gt(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) > b.numerator.mul(a.denominator);
    }

    function gte(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) >= b.numerator.mul(a.denominator);
    }

    function lt(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) < b.numerator.mul(a.denominator);
    }

    function lte(Fraction memory a, Fraction memory b) internal pure onlyValid(a) onlyValid(b) returns (bool) {
        return a.numerator.mul(b.denominator) <= b.numerator.mul(a.denominator);
    }
}