//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseSupportsFee} from "./BaseSupportsFee.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

contract Fee is BaseSupportsFee, BaseImpersonate {
    // Set the fee recipient
    function testSetFeeRecipient() public {
        _supportsFee.setFeeRecipient(_feeRecipient);

        assertEq(_supportsFee.feeRecipient(), _feeRecipient);
    }

    // Set the fee
    function testSetFee() public {
        _supportsFee.setFeePercent(_feePercent, _feeDenominator);

        (uint256 newPercent, uint256 newDenominator) = _supportsFee.feePercent();
        assertEq(newPercent, _feePercent);
        assertEq(newDenominator, _feeDenominator);
    }
}
