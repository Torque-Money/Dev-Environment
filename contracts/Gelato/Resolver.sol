//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ResolverResolve} from "./ResolverResolve.sol";

contract Resolver is Initializable, ResolverResolve {
    function initialize(
        address taskTreasury_,
        address depositReceiver_,
        address ethAddress_,
        address marginLong_,
        address converter_
    ) external initializer {
        initializeResolverCore(taskTreasury_, depositReceiver_, ethAddress_, marginLong_, converter_);
    }
}
