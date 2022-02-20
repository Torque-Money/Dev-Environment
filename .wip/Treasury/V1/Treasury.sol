//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {TreasuryRedeem} from "./TreasuryRedeem.sol";

contract Treasury is Initializable, TreasuryRedeem {
    function initialize(address oracle_, address reserveToken_) external initializer {
        initializeTreasuryCore(oracle_, reserveToken_);
    }
}
