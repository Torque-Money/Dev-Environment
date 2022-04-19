//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library AssertUtils {
    using SafeMath for uint256;

    // Check if two numbers are equal with a given percentage of error allowed.
    function assertApproxEq(
        uint256 a,
        uint256 b,
        uint256 percent,
        uint256 denominator
    ) internal pure {
        require(denominator != 0, "AssertUtils: Denominator cannot equal 0");
        require(percent <= denominator, "AssertUtils: Percent cannot be greater than denominator");

        uint256 compPercent = denominator.sub(percent);

        assert(a.mul(denominator) >= compPercent.mul(b));
    }
}
