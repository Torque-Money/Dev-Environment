//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Config} from "../helpers/Config.sol";
import {Empty} from "../helpers/Empty.sol";
import {AssertUtils} from "../helpers/AssertUtils.sol";

abstract contract Base is Test {
    address internal _empty;

    uint256 internal _fosPercent;
    uint256 internal _fosDenominator;

    function setUp() public virtual {
        _empty = address(new Empty());

        _fosPercent = Config.getFosPercent();
        _fosDenominator = Config.getFosDenominator();
    }

    function _assertApproxEq(uint256 a, uint256 b) internal view {
        AssertUtils.assertApproxEq(a, b, _fosPercent, _fosDenominator);
    }
}
