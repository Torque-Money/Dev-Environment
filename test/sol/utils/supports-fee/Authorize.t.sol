//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseSupportsFee} from "./BaseSupportsFee.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

contract AuthorizeTest is BaseSupportsFee, BaseImpersonate {
    // Check that unauthorized accounts cant set the fee recipient
    function testFailSetFeeRecipient() public impersonate(vm, _empty) {
        _supportsFee.setFeeRecipient(_feeRecipient);
    }

    // Check that unauthorized accounts cant set the fee
    function testFailSetFee() public impersonate(vm, _empty) {
        _supportsFee.setFeePercent(_feePercent, _feeDenominator);
    }
}
