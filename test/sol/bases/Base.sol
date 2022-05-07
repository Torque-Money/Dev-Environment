//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {Config} from "../helpers/Config.sol";
import {Empty} from "../helpers/Empty.sol";

abstract contract Base is Test {
    using SafeMathUpgradeable for uint256;

    address internal _empty;

    function setUp() public virtual {
        _empty = address(new Empty());
    }

    function _assertApproxEq(uint256 a, uint256 b) internal {
        (uint256 fosPercent, uint256 fosDenominator) = Config.getFos();

        uint256 maxDelta = MathUpgradeable.max(a, b).mul(fosPercent).div(fosDenominator);
        assertApproxEqAbs(a, b, maxDelta);
    }

    receive() external payable {}
}
