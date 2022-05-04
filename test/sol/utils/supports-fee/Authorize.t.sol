//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseSupportsFee} from "./BaseSupportsFee.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

contract Authorize is BaseSupportsFee, BaseImpersonate {
    // Check that an approved account will be able to use the admin set fee recipient function
    function testSetFeeRecipient() public {
        _supportsFee.setFeeRecipient(_feeRecipient);
    }

    // Check that an approved account will be able to use the admin set fee function
    function testSetFee() public {
        _supportsFee.setFeePercent(_feePercent, _feeDenominator);
    }

    // Check that a non approved account will not be able to use the admin set fee recipient function
    function testFailUnauthorizedSetFeeRecipient() public impersonate(vm, _empty) {
        _supportsFee.setFeeRecipient(_feeRecipient);
    }

    // Check that a non approved account will not be able to use the admin set fee function
    function testFailUnauthorizedSetFee() public impersonate(vm, _empty) {
        _supportsFee.setFeePercent(_feePercent, _feeDenominator);
    }
}
