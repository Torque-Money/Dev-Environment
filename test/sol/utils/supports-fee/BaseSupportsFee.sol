//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Base} from "../../bases/Base.sol";

import {MockSupportsFee} from "../../../mocks/MockSupportsFee.sol";
import {Config} from "../../helpers/Config.sol";

abstract contract BaseSupportsFee is Base {
    MockSupportsFee internal _supportsFee;

    address internal _feeRecipient;
    uint256 internal _feePercent;
    uint256 internal _feeDenominator;

    function setUp() public virtual override {
        super.setUp();

        _feeRecipient = _empty;
        (_feePercent, _feeDenominator) = Config.getFee();
        _supportsFee = new MockSupportsFee(_feeRecipient, _feePercent, _feeDenominator);
    }
}
