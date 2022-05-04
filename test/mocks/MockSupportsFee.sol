//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {SupportsFeeUpgradeable} from "../../src/utils/SupportsFeeUpgradeable.sol";

contract MockSupportsFee is Initializable, SupportsFeeUpgradeable {
    constructor(
        address recipient,
        uint256 percent,
        uint256 denominator
    ) {
        _initialize(recipient, percent, denominator);
    }

    function _initialize(
        address recipient,
        uint256 percent,
        uint256 denominator
    ) internal initializer {
        __SupportsFee_init(recipient, percent, denominator);
    }
}
