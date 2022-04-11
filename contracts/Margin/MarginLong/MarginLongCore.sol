//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {MarginCollateral} from "../MarginCollateral.sol";
import {MarginBorrowers} from "../MarginBorrowers.sol";

abstract contract MarginLongCore is MarginCollateral, MarginBorrowers {}
